# Mirrors what is available in core
class BuildpackDockerfileProcessor
  def self.append_line(contents, line)
    lines = contents.lines
    lines.push("\n")
    lines.push(line)

    lines.join
  end

  def self.build_postlude_lines
    [
      "# BEGIN GENERATED SECTION",
      "WORKDIR /app",
      "ARG CODECRAFTERS_SERVER_URL",
      "ARG REPOSITORY_ID",
      "ENV CODECRAFTERS_SERVER_URL=$CODECRAFTERS_SERVER_URL",
      "ENV REPOSITORY_ID=$REPOSITORY_ID",
      "COPY . /app",
      grouped_run(
        "mkdir -p /var/opt",
        # Copy test runner binary
        "mv /app/test-runner/test-runner /var/opt/test-runner",
        "chmod +x /var/opt/test-runner",
        "rm -rf /app/test-runner",
        # Copy tester binary
        "mv /app/tester /var/opt/tester",
        # Ensure all files are readable by everyone (some languages have files only readable by user)
        "chmod -R +rw /app",
        "sh -c '(test -d /app-cached && chmod -R ugo+rwx /app-cached) || true'"
      ),
      "# END GENERATED SECTION"
    ]
  end

  def self.build_prelude_lines(from_line)
    [
      "# BEGIN GENERATED SECTION",

      # Git is required to pull repository changes. I don't think we need curl anymore, not sure...
      case from_line
      when /alpine/
        "RUN apk add --update-cache --upgrade git curl"
      when /buster/, /slim/, /focal/, /bullseye/, /bookworm/
        "RUN apt-get update && apt-get install -y git curl"
      when /dart/
        "RUN apt-get update && apt-get install -y git curl" # Dart doesn't have OS type in its FROM line
      else
        raise "Unknown from_line: #{from_line}"
      end,

      "CMD [\"/var/opt/test-runner\", \"run_tests\"]",
      "ENV TESTER_DIR=/var/opt/tester",
      "# END GENERATED SECTION"
    ]
  end

  def self.grouped_run(*commands)
    ("RUN " + commands.join(" && "))
  end

  def self.insert_line(contents, index, line)
    lines = contents.lines
    lines.insert(index, line + "\n")
    lines.join
  end

  def self.process(dockerfile_contents)
    lines = dockerfile_contents.lines.map(&:strip)
    from_line_index = lines.index { |line| line.start_with?("FROM") }

    raise "No FROM line found. Dockerfile: #{dockerfile_contents}" unless from_line_index.present?

    from_line = lines[from_line_index]

    first_user_line_index = lines.index { |line| line.start_with?("USER") }

    # If there's a USER line, we'll insert the prelude after the first USER line. Else, we'll insert it after the FROM line.
    pivot_index = first_user_line_index || from_line_index

    [
      lines[0..pivot_index].join("\n"),
      build_prelude_lines(from_line).join("\n"),
      lines[(pivot_index + 1)..].join("\n"),
      build_postlude_lines.join("\n")
    ].join("\n\n").strip.gsub(/\n\n\n+/, "\n\n") + "\n"
  end
end
