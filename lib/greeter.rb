# 動作確認用のサンプルクラス。
# 実際の教材クラスを追加したら削除してよい。
class Greeter
  def initialize(name = 'everyone')
    @name = name
  end

  def hello
    "Hello, #{@name}!"
  end
end
