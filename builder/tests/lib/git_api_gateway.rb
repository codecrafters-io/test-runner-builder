# Copied from core
class GitApiGateway
  def create_repository(repository_name)
    response = HTTParty.post(
      "http://localhost:6333/api/v1/repositories",
      body: {
        name: repository_name
      }.to_json,
      headers: {"Content-Type" => "application/json"}
    )

    if response.code.eql?(200)
      response.parsed_response
    else
      raise "Error creating repository. Status: #{response.code}, Body: #{response.body}"
    end
  end

  def delete_repository(repository_name)
    response = HTTParty.delete("http://localhost:6333/api/v1/repositories/#{repository_name}")

    if response.code.eql?(200)
      response.parsed_response
    elsif response.code.eql?(404)
      Sentry.capture_message("Repository not found when deleting", extra: {repository_name: repository_name})
      nil # Idempotency
    else
      raise "Error deleting repository. Status: #{response.code}, Body: #{response.body}"
    end
  end

  def fetch_commit(repository_id, commit_sha)
    response = HTTParty.get("http://localhost:6333/api/v1/repositories/#{repository_id}/commits/#{commit_sha}")

    if response.code.eql?(200)
      response.parsed_response
    elsif response.code.eql?(404)
      nil
    else
      raise "Error fetching commit. Status: #{response.code}, Body: #{response.body}"
    end
  end
end
