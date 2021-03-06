# Run skill changes against the last major release of Mycroft Core but install
# the latest version of all skills.
ARG major_release
FROM voight-kampff-mark-1:${major_release} as config_builder
ARG pull_request
ARG platform
ARG branch_name
ARG repo_url
ARG github_user
ARG github_api_key
ENV GITHUB_API_KEY=$github_api_key
RUN msm update
# Load updated test cases for default skills
RUN python -m test.integrationtests.voight_kampff.test_setup \
    --config test/integrationtests/voight_kampff/default.yml \
    --platform $platform
WORKDIR /opt/mycroft/mycroft-core
COPY test-requirements.txt skill-test-requirements.txt
RUN .venv/bin/python -m pip install -r skill-test-requirements.txt
COPY build_test_config.py .
RUN .venv/bin/python build_test_config.py --pull-request $pull_request --platform $platform

# Use multi-stage build to forget the GitHub credentials from the previous stage
FROM config_builder as test_setup
ARG platform
ARG branch_name
ARG repo_url
# Load test cases for skill to test
RUN python -m test.integrationtests.voight_kampff.test_setup \
    --config test_skill.yml \
    --platform $platform \
    --branch $branch_name \
    --repo-url $repo_url

RUN mkdir /etc/mycroft || true
RUN echo '{"tts": {"module": "dummy"}}' > /etc/mycroft/mycroft.conf
ENV PYTHONPATH /opt/mycroft/mycroft-core/
# Set working directory for testing
WORKDIR /opt/mycroft/mycroft-core/test/integrationtests/voight_kampff
ENTRYPOINT ["./run_test_suite.sh"]
