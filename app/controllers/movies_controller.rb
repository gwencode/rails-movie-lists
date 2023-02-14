# frozen_string_literal: true


# Controller for the Movie model
class MoviesController < ApplicationController
  API_KEY = ENV['API_KEY']
  skip_before_action :authenticate_user!, only: %i[index show]
  before_action :set_movie, only: %i[show]
  before_action :set_user, only: %i[show]

  def index
    popular_movies = Movie.where(popular: true)
    if params[:query].present?
      popular_movies = popular_movies.where('title ILIKE ?', "%#{params[:query]}%")
    end

    if params[:genre].present?
      popular_movies = popular_movies.joins(:genres).where(genres: { id: params[:genre].to_i })
    end

    @movies = popular_movies.sort_by { |movie| movie.id }
  end

  def show
    if current_user
      @bookmark = Bookmark.new
      @list = List.new(user_id: @user)
      @lists = @user.lists.where.not(id: Bookmark.where(movie: @movie).pluck(:list_id))
      # doc for pluck : https://apidock.com/rails/ActiveRecord/Calculations/pluck
    end
    add_details(@movie) if @movie.overview.nil?
    add_director(@movie) if @movie.director.nil?
    add_movie(@movie) if @movie.video_id.nil?
    parse_actors_casts(@movie) if @movie.actors.empty?
    @reco_movies = @movie.reco_movies
  end

  private

  def set_movie
    @movie = Movie.find(params[:id])
  end

  def set_user
    @user = current_user
  end

  def add_details(movie)
    url_movie = "https://api.themoviedb.org/3/movie/#{movie[:api_id]}?api_key=#{API_KEY}&language=en-US"
    movie_details_serialized = URI.open(url_movie).read
    movie_details = JSON.parse(movie_details_serialized)
    movie.update(overview: movie_details['overview'],
                 backdrop_url: movie_details['backdrop_path'].nil? ? '' : "https://image.tmdb.org/t/p/w1280#{movie_details['backdrop_path']}",
                 release_date: movie_details['release_date'],
                 run_time: movie_details['runtime'],
                 budget: movie_details['budget'],
                 revenue: movie_details['revenue'],
                 rating: movie_details['vote_average'])
  end

  def add_movie(movie)
    url_videos = "https://api.themoviedb.org/3/movie/#{movie[:api_id]}/videos?api_key=#{API_KEY}&language=en-US"
    videos_details_serialized = URI.open(url_videos).read
    videos_details = JSON.parse(videos_details_serialized)
    videos = videos_details['results']
    # find the first video that is a trailer
    video_details = videos.find { |video| video['type'] == 'Trailer' }
    movie.update(video_id: video_details['key']) if video_details
  end

  def add_director(movie)
    url_credits = "https://api.themoviedb.org/3/movie/#{movie[:api_id]}/credits?api_key=#{API_KEY}&language=en-US"
    credits_serialized = URI.open(url_credits).read
    crew = JSON.parse(credits_serialized)['crew']
    director = crew.find { |member| member['job'] == 'Director' }
    director_name = director.nil? ? '' : director['name']
    movie.update(director: director_name)
  end

  def parse_actors_casts(movie)
    url_credits = "https://api.themoviedb.org/3/movie/#{movie[:api_id]}/credits?api_key=#{API_KEY}&language=en-US"
    credits_serialized = URI.open(url_credits).read
    credits = JSON.parse(credits_serialized)
    max_10_casts = credits['cast'].first(10)
    max_10_casts.each do |cast|
      next if cast['profile_path'].nil?

      actor = Actor.find_or_create_by(name: cast['name'],
                                      api_id: cast['id'],
                                      picture_url: "https://image.tmdb.org/t/p/w500#{cast['profile_path']}")
      next if actor.id.nil?

      Cast.create(actor: actor,
                  movie: movie,
                  character: cast['character'],
                  order: cast['order'],
                  actor_api_id: cast['id'])
    end
  end
end

### pluck documentation

# pluck(*column_names) public
# Use #pluck as a shortcut to select one or more attributes without loading a bunch of records just to grab the attributes you want.

# Person.pluck(:name)
# instead of

# Person.all.map(&:name)
# Pluck returns an Array of attribute values type-casted to match the plucked column names, if they can be deduced. Plucking an SQL fragment returns String values by default.

# Person.pluck(:name)
# # SELECT people.name FROM people
# # => ['David', 'Jeremy', 'Jose']

# Person.pluck(:id, :name)
# # SELECT people.id, people.name FROM people
# # => [[1, 'David'], [2, 'Jeremy'], [3, 'Jose']]

# Person.distinct.pluck(:role)
# # SELECT DISTINCT role FROM people
# # => ['admin', 'member', 'guest']

# Person.where(age: 21).limit(5).pluck(:id)
# # SELECT people.id FROM people WHERE people.age = 21 LIMIT 5
# # => [2, 3]

# Person.pluck('DATEDIFF(updated_at, created_at)')
# # SELECT DATEDIFF(updated_at, created_at) FROM people
# # => ['0', '27761', '173']
