require 'set'
require 'pathname'


module MonkeyReloader
  class << self

    @@hash = 'HEAD'
    @@whitelist = nil
    @@blacklist = nil


    def init(whitelist = [], blacklist = [])
      @@whitelist = Set.new
      self.whitelist whitelist

      @@blacklist = Set.new
      self.blacklist blacklist

      update_hash

      self
    end

    def load
      wlist = whitelist
      blist = blacklist

      files = changed_files.select do |file|
        wlist.include? file
      end.reject do |file|
        blist.include? file
      end

      update_hash
      pwd = Pathname.new Dir.pwd

      files.each do |file|
        Kernel.load file
      end.map do |file|
        # map back to relative pathnames for convenience
        Pathname.new(file).relative_path_from(pwd).to_s
      end
    end

    def whitelist(files = [])
      @@whitelist ||= Set.new

      expand_paths @@whitelist.merge parse_paths files
    end

    def blacklist(files = [])
      @@blacklist ||= Set.new

      expand_paths @@blacklist.merge parse_paths files
    end


    private

    def parse_paths(paths = [])
      Array(paths).map do |path|
        path = File.expand_path path

        if path.include? '*'
          path
        elsif Dir.exists? path
          "#{path}/**/*.rb"
        elsif File.exists? path
          unless /\.rb$/.match path
            raise ArgumentError.new ".rb files only: #{path}"
          end

          path
        else
          raise ArgumentError.new "path not found: #{path}"
        end
      end
    end

    def expand_paths(paths = [])
      # recalculate path expansions - caching will miss filesystem changes
      Array(paths).map do |path|
        Dir[path]
      end.flatten
    end

    def update_hash
      # get current git branch hash
      @@hash = `git rev-parse HEAD`.strip
    end

    def changed_files
      # return a list of changed files

      files = Set.new
      awk = "awk '{ print $2 }'"

      # find recent changes
      files.merge `git status -s | #{awk}`.split

      # find committed changes if there was a branch change / rebase
      files.merge `git diff --name-status HEAD..#{@@hash} | #{awk}`.split

      # filter for ruby files and those that dissapeared during
      # a branch change
      files.select do |file|
        /\.rb$/.match file and File.exists? file
      end.map do |file|
        File.expand_path file
      end
    end

  end
end
