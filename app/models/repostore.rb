class Repostore < ActiveRecord::Base
	store_accessor :settings

	def redis_key(str)
	  "#{self.name}:#{self.id}:#{str}"
	end

	def get_value(key)
      issues_list = $redis.get(self.redis_key(key.to_sym))
 	end
end
