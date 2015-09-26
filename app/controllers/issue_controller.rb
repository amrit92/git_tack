class IssueController < ApplicationController

	TOTAL_OPEN = "Total open issues"
	PAST_24 = "Issues opened in past 24 hrs"
	BET_24_7 = "Issues opened more than 24 hours ago but less than 7 days ago"
	MORE_THAN_7 = "Issues opened more than 7 days ago"
	def index
		token = $GIT_TOKEN

		@owner, @repo = params[:user].split('/')
		git_client = Github.new auto_pagination: true, oauth_token: token, user: @owner, repo: @repo
		repos = git_client.repos.list.collect(&:full_name)
		if repos && repos.map{|s| s.downcase}.include?(params[:user])
			@repostore = Repostore.where(name: "#{@owner}.#{@repo}").first
			@repostore = Repostore.new(name: "#{@owner}.#{@repo}") unless @repostore
			values_hash = get_issues(@owner, @repo, git_client)
			update_store(values_hash)
			make_calculations
		else
			flash[:notice] = "Repo doesnt exist"
			redirect_to :back
		end
	end

	def clickme
		@repostore = Repostore.find(params[:repostore_id])
		@issue_name = params[:submit]
	    @display =  JSON.parse $redis.get(@repostore.redis_key(@issue_name.to_sym))
	  	@display.map!{ |h| h.slice("html_url", "id", "user", "title")}
	    respond_to do |format|
	        format.js { render :layout => false }
	    end
	end

	def get_issues(owner, repo, git_client, options={})
		@issues_list = git_client.issues.list(user: owner, repo: repo, state: "open")

		@issues_last_24_hours = git_client.issues.list(user: owner, repo: repo, state: "open", filter: 'created', since: Time.parse("#{1.days.ago}").iso8601)

		@issues_last_7_days = git_client.issues.list(user: owner, repo: repo, state: "open", filter: 'created', since: Time.parse("#{7.days.ago}").iso8601)
		values_hash = {
			issues_list: @issues_list,
			issues_last_24_hours: @issues_last_24_hours,
			issues_last_7_days: @issues_last_7_days,
			table_data: @table_data
		}
		@table_data = {
			"Total open issues" => @issues_list.size,
			"Issues opened in past 24 hrs" => @issues_last_24_hours.size,
			"Issues opened more than 24 hours ago but less than 7 days ago" => @issues_last_7_days.size - @issues_last_24_hours.size,
			"Issues opened more than 7 days ago" => @issues_list.size - @issues_last_7_days.size
		}
		values_hash
	end
	

	def update_store(values_hash)
		@repostore.save
		$redis.multi do
			values_hash.each do |k,v|
				$redis.set(@repostore.redis_key(k.to_sym), v.to_json)
			end
		end
	end

	def make_calculations
		hash_data = {}
		[:issues_list, :issues_last_24_hours, :issues_last_7_days].each{|key| hash_data[key] = JSON.parse ($redis.get(@repostore.redis_key(key.to_sym)))}
		hash_data[TOTAL_OPEN] = (hash_data[:issues_list])
		hash_data[PAST_24] = (hash_data[:issues_last_24_hours])
		hash_data[BET_24_7] = (hash_data[:issues_last_7_days]) - (hash_data[:issues_last_24_hours])
		hash_data[MORE_THAN_7] = (hash_data[:issues_list])- (hash_data[:issues_last_7_days])
		hash_data.each do |k,v|
			$redis.set(@repostore.redis_key(k.to_sym), v.to_json)
		end
	end
end
