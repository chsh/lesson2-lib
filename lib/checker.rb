require "net/http"
require "uri"
require "set"

=begin
使い方;

checker = Checker.new(timeout: 3)

checker.exist?("https://www.ruby-lang.org/ja/")  #=> true
checker.check("https://example.com/nope").status #=> 404
checker.check("ftp://example.com").error         #=> "不正なURL: http(s) のみ対応"
=end

class Checker
  Result = Struct.new(:url, :final_url, :status, :error, keyword_init: true) do
    def exist? = status&.between?(200, 299) || false
    def ok?    = error.nil?
    def to_s   = exist? ? "OK #{status} #{final_url}" : (error || "NG #{status}")
  end

  MAX_REDIRECTS = 5

  def initialize(timeout: 5, max_redirects: MAX_REDIRECTS, user_agent: "Checker/1.0")
    @timeout = timeout
    @max_redirects = max_redirects
    @user_agent = user_agent
  end

  def check(url)
    uri = normalize(url)
    seen = Set.new
    current = uri

    @max_redirects.times do
      return redirect_loop(url, current) unless seen.add?(current.to_s)

      res = request(current)
      case res
      when Net::HTTPRedirection
        location = res["location"] or return result(url, current, res.code.to_i)
        current = URI.join(current, location)
      when Net::HTTPMethodNotAllowed, Net::HTTPNotImplemented
        res = request(current, method: Net::HTTP::Get)
        return result(url, current, res.code.to_i)
      else
        return result(url, current, res.code.to_i)
      end
    end

    result(url, current, nil, error: "リダイレクトが#{@max_redirects}回を超えました")
  rescue ArgumentError, URI::InvalidURIError => e
    result(url, nil, nil, error: "不正なURL: #{e.message}")
  rescue Net::OpenTimeout, Net::ReadTimeout
    result(url, nil, nil, error: "タイムアウト (#{@timeout}s)")
  rescue SocketError => e
    result(url, nil, nil, error: "名前解決に失敗: #{e.message}")
  rescue SystemCallError, OpenSSL::SSL::SSLError, Net::HTTPBadResponse => e
    result(url, nil, nil, error: "#{e.class}: #{e.message}")
  end

  def exist?(url) = check(url).exist?

  private

  def normalize(url)
    uri = URI.parse(url.to_s.strip)
    raise ArgumentError, "http(s) のみ対応" unless uri.is_a?(URI::HTTP)
    raise ArgumentError, "ホスト名がありません" if uri.host.nil? || uri.host.empty?
    uri
  end

  def request(uri, method: Net::HTTP::Head)
    Net::HTTP.start(uri.host, uri.port,
                    use_ssl: uri.scheme == "https",
                    open_timeout: @timeout, read_timeout: @timeout) do |http|
      http.request(method.new(uri, "User-Agent" => @user_agent))
    end
  end

  def result(url, current, status, error: nil)
    Result.new(url: url, final_url: current&.to_s, status: status, error: error)
  end

  def redirect_loop(url, current)
    result(url, current, nil, error: "リダイレクトループ: #{current}")
  end
end
