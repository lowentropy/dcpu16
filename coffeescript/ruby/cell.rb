class Cell
  def initialize value=0
    @value = value
  end
  def get
    @value
  end
  def set value
    @value = value
  end
  def post
    @post ||= Post.new(self)
  end
  def pre
    @pre ||= Pre.new(self)
  end
  def dec
    @value = (@value - 1) & 0xffff
  end
  def inc
    @value = (@value + 1) & 0xffff
  end
end

class Post
  def initialize cell
    @cell = cell
  end
  def inc
    @cell.get.tap { @cell.inc }
  end
  def dec
    @cell.get.tap { @cell.dec }
  end
end

class Pre
  def initialize cell
    @cell = cell
  end
  def inc
    @cell.inc
  end
  def dec
    @cell.dec
  end
end

class ConstCell
  def set
  end
end