module MonkeyReloader
  def self.load(blacklist = [])
    cmd = "git status -s | grep '.rb' | awk '{ print $2 }'"
    `#{cmd}`.split.reject do |file|
      blacklist.include? file
    end.each do |file|
      Kernel.load file unless blacklist.include? file
    end
  end
end
