require "net/http"
require "uri"

class Scraper
  def initialize(url)
    @url = url
  end

  def url
    @url
  end

  def grab(url, limit: 5, timeout: 10)
    raise ArgumentError, "リダイレクトが多すぎます: #{url}" if limit <= 0

    uri = URI.parse(url)
    raise ArgumentError, "http(s) のみ対応: #{url}" unless uri.is_a?(URI::HTTP)

    res = Net::HTTP.start(uri.host, uri.port,
                          use_ssl: uri.scheme == "https",
                          open_timeout: timeout, read_timeout: timeout) do |http|
      http.request(Net::HTTP::Get.new(uri, "User-Agent" => "grab/1.0"))
    end

    case res
    when Net::HTTPSuccess      then to_utf8(res)
    when Net::HTTPRedirection  then grab(URI.join(url, res["location"]).to_s, limit: limit - 1, timeout:)
    else raise "HTTP #{res.code} #{res.message}: #{url}"
    end
  end

  def to_utf8(res)
    charset = res.type_params["charset"]
    body = res.body.to_s
    return body unless charset

    body.force_encoding(charset).encode("UTF-8", invalid: :replace, undef: :replace)
  rescue ArgumentError, Encoding::ConverterNotFoundError
    body.force_encoding(Encoding::UTF_8)
  end
end
