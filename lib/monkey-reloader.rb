module MonkeyReloader
  class << self


    def init(blacklist = [])
      @@blacklist = Array(blacklist)
      update_hash

      true
    end

    def load
      files = changed_files.reject do |file|
        @@blacklist.include? file
      end
      update_hash

      files.each do |file|
        Kernel.load file
      end
    end


    private

    def update_hash
      @@hash = `git rev-parse HEAD`.strip
    end

    def changed_files
      files = []
      awk = "awk '{ print $2 }'"

      # find recent changes
      files += `git status -s | #{awk}`.split

      # find committed changes if there was a branch change / rebase
      files += `git diff --name-status HEAD..#{@@hash} | #{awk}`.split

      # filter for ruby files and those that dissapeared during
      # a branch change
      files.select do |file|
        /\.rb$/.match file and File.exists? file
      end
    end

  end
end
