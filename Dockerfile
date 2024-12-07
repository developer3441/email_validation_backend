FROM ruby:3.3.0-alpine as Builder

ENV APP_HOME="/var/lib/truemail-rack" \
    TMP="/var/lib/truemail-rack/tmp"

# Install build dependencies
RUN apk add --virtual build-dependencies make cmake g++

# Set working directory for the app
WORKDIR $APP_HOME

# Copy local files into the Docker image
COPY . $APP_HOME

# Install bundler and dependencies
RUN gem i bundler -v $(tail -1 Gemfile.lock | tr -d ' ') && \
    BUNDLE_FORCE_RUBY_PLATFORM=1 && \
    bundle check || bundle install --system --without=test development && \
    rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -regex ".*\.[coh]" -delete && \
    apk del build-dependencies

FROM ruby:3.3.0-alpine

ENV INFO="Truemail lightweight rack based web API 🚀" \
    APP_USER="truemail" \
    APP_HOME="/var/lib/truemail-rack" \
    VERIFIER_EMAIL="developer3441@gmail.com" \
    ACCESS_TOKENS="OKgRkg0OZI6clEpVRPFHLfO8hgV6P5qbp0rSxvIxJM3P6mgDP30ERl9VIRR48GS4" \
    APP_PORT="8080"

LABEL description=$INFO

# Install runtime dependencies
RUN apk add curl && \
    adduser -D $APP_USER

# Copy bundled gems and application code from the Builder stage
COPY --from=Builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=Builder --chown=truemail:truemail $APP_HOME $APP_HOME

# Set permissions and working directory
USER $APP_USER
WORKDIR $APP_HOME

# Expose application port
EXPOSE $APP_PORT

# Start the application
CMD echo $INFO && thin -R config.ru -a 0.0.0.0 -p $APP_PORT -e production start

# Healthcheck
HEALTHCHECK --interval=5s --timeout=3s \
  CMD curl -f http://localhost:${APP_PORT}/healthcheck || exit 1
