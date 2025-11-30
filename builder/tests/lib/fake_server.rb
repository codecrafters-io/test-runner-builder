require "sinatra/base"

class FakeServer < Sinatra::Base
  set :port, 6331
  set :bind, "0.0.0.0"

  error do
    content_type :json
    status 500

    {
      error: env["sinatra.error"].message,
      backtrace: env["sinatra.error"].backtrace.join("\n")
    }.to_json
  end

  get "/" do
    "hello"
  end

  # --- Public Interface Starts ---

  post "/services/test_runner_builder/finalize_test_runner_build" do
    halt 400, {error: "invalid content type"}.to_json unless request.content_type == "application/json"

    json = JSON.parse(request.body.read)

    build = TestRunnerBuild.find_by(id: json.fetch("test_runner_build_id"))
    halt 404, {error: "build not found"}.to_json if build.nil?

    build.update!(status: json.fetch("status"), logs_base64: json.fetch("logs_base64"))
  end
end
