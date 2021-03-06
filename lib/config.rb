module GitAuth
  class Config
    
    @@REGEX_SECTIONS = /\[([^\]]+)\]([^\[]+)/mix
    
    attr_accessor :settings, :groups, :readers, :writers
    attr_reader :repo
    
    def initialize(file, repo)
 	  @repo = repo
	  @groups = {}
	  @writers = []
          @readers = Group.new("Readers", [], self)

 	  process_config_file File.read(file)
    end

    def self.current_config(repo)
      
        current_path = Pathname.new(File.dirname(__FILE__)).realpath
        
        @config = Config.new( File.join( current_path, "../config/auth.conf" ), repo)
      
        current_path = Pathname.new( File.join( @config.settings["git_dir"] , repo, "git_auth.conf"  )).realpath
      	@config.process_config_file(File.read(current_path), false)
      	
	@config.groups.each { |name, gr| gr.expand! }
	@config.writers.each { |r| r.expand! }
	@config.readers.expand!

      	@config
    end
  
    def process_config_file(config_file_contents, global = true )
      
      sections = config_file_contents.scan(@@REGEX_SECTIONS)
      
      sections.each do |name, data|
      		case name.strip
  				when "settings" :
				     
				     @settings = {} if global
				     
				      data.split("\n").reject { |g| g.strip.empty? }.each do |setting|
				        key, value = setting.strip.split("=").collect { |part| part.strip }
				        @settings[key] = value
				      end
				      
				when "groups" :
				      @groups = {} if global
				      data.split("\n").reject { |g| g.strip.empty? }.each do |group|
				        name, members = group.strip.split("=").collect { |part| part.strip }
				        @groups[name] = Group.new(name, members.split(",").collect { |mem| mem.strip }, self)
				      end
				
				when "readers" :
					@readers = Group.new("Readers", 
							 data.split("\n").reject { |r| r.strip.empty? }.collect { |r| r.strip }, self)
 				
 				when "writers" :
					@writers = []
  					data.split("\n").reject { |r| r.strip.empty? }.each do |rule|
    
				        members_raw, pattern = rule.strip.split("=").collect { |p| p.strip }
	    				members = members_raw.split(",").collect { |m| m.strip }

    					@writers << Rule.new(members, pattern, self)
			      	end
				
  			end
  	  end
  	  
    end
    
    
  end
  
end
