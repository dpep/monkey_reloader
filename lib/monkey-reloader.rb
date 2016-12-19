require 'set'
require 'pathname'


module MonkeyReloader
  class << self

    @@hash = 'HEAD'
    @@whitelist = nil
    @@blacklist = nil


    def config(opts = {})
      whitelist = opts[:whitelist]
      if !whitelist or whitelist.empty?
        raise ArgumentError.new 'whitelist expected'
      end

      blacklist = opts.key?(:blacklist) ? opts[:blacklist] : [
        # by default, block dangerous Rails behavior
        'bin',
        'config',
        'db',
        'log',
        'script',
        'spec',
      ].select {|dir| Dir.exists? dir}

      @@whitelist = Set.new
      self.whitelist whitelist

      @@blacklist = Set.new
      self.blacklist blacklist

      update_hash

      self
    end

    def load
      # reload all changed files
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
      # recalculate path expansions, but keep relative paths.
      # note that caching will miss filesystem changes

      pwd = Pathname.new Dir.pwd
      Array(paths).map do |path|
        Dir[path]
      end.flatten.map do |path|
        # map back to relative paths
        Pathname.new(path).relative_path_from(pwd).to_s
      end
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
      end
    end

  end
end
