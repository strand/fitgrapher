class ActivitiesController < ApplicationController
  require "fitgem"
  require "pp"
  require "yaml"
  # GET /activities
  # GET /activities.json
  def index
    @activities = Activity.all

    fitgem_script
    @fitbit_activities = get_fitbit_activities

    @steps     = {}
    @fitbit_activities.each do |activity|
      @steps.merge!({ activity["date"] => activity["summary"]["steps"] })
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @activities }
    end
  end

  # GET /activities/1
  # GET /activities/1.json
  def show
    @activity = Activity.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @activity }
    end
  end

  # GET /activities/new
  # GET /activities/new.json
  def new
    @activity = Activity.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @activity }
    end
  end

  # GET /activities/1/edit
  def edit
    @activity = Activity.find(params[:id])
  end

  # POST /activities
  # POST /activities.json
  def create
    @activity = Activity.new(params[:activity])

    respond_to do |format|
      if @activity.save
        format.html { redirect_to @activity, notice: 'Activity was successfully created.' }
        format.json { render json: @activity, status: :created, location: @activity }
      else
        format.html { render action: "new" }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /activities/1
  # PUT /activities/1.json
  def update
    @activity = Activity.find(params[:id])

    respond_to do |format|
      if @activity.update_attributes(params[:activity])
        format.html { redirect_to @activity, notice: 'Activity was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activities/1
  # DELETE /activities/1.json
  def destroy
    @activity = Activity.find(params[:id])
    @activity.destroy

    respond_to do |format|
      format.html { redirect_to activities_url }
      format.json { head :no_content }
    end
  end

  def fitgem_script
    # Load the existing yml config
    config = begin
      Fitgem::Client.symbolize_keys(YAML.load(File.open("config/fitgem.yml")))
    rescue ArgumentError => e
      puts "Could not parse YAML: #{e.message}"
      exit
    end

    @client = Fitgem::Client.new(config[:oauth])

    # With the token and secret, we will try to use them
    # to reconstitute a usable Fitgem::Client
    if config[:oauth][:token] && config[:oauth][:secret]
      begin
        access_token = @client.reconnect(config[:oauth][:token], config[:oauth][:secret])
      rescue Exception => e
        puts "Error: Could not reconnect Fitgem::Client due to invalid keys in config/fitgem.yml"
        exit
      end
    # Without the secret and token, initialize the Fitgem::Client
    # and send the user to login and get a verifier token
    else
      request_token = @client.request_token
      token = request_token.token
      secret = request_token.secret

      puts "Go to http://www.fitbit.com/oauth/authorize?oauth_token=#{token} and then enter the verifier code below"
      verifier = gets.chomp

      begin
        access_token = @client.authorize(token, secret, { :oauth_verifier => verifier })
      rescue Exception => e
        puts "Error: Could not authorize Fitgem::Client with supplied oauth verifier"
        exit
      end

      puts 'Verifier is: '+verifier
      puts "Token is:    "+access_token.token
      puts "Secret is:   "+access_token.secret

      user_id = @client.user_info['user']['encodedId']
      puts "Current User is: "+user_id

      config[:oauth].merge!(:token => access_token.token, :secret => access_token.secret, :user_id => user_id)

      # Write the whole oauth token set back to the config file
      File.open("config/fitgem.yml", "w") {|f| f.write(config.to_yaml) }
    end
  end

  def get_fitbit_activities
    if @client.user_info["user"].blank?
      return YAML.load File.open "config/summaries.yml"
    end

    first_day   = @client.user_info["user"]["memberSince"]
    date_range  = first_day.to_date..Time.now.strftime("%Y-%m-%d").to_date

    fitgem_activities = date_range.map do |date|
      @client.activities_on_date(date.to_s).merge!({ "date" => date.to_s })
    end
  end
end
