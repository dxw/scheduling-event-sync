ruby File.read(".ruby-version").strip

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem "breathe", "0.3.6"
gem "dotenv"
gem "memo_wise"
gem "productive", "0.6.86"
gem "rake"
gem "rollbar"

gem "benchmark"
gem "bigdecimal"
gem "logger"
gem "mutex_m"

group :development do
  gem "standard"
end

group :test do
  gem "rspec"
end

group :development, :test do
  gem "byebug"
end
