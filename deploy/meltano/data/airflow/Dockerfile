FROM apache/airflow:2.2.2-python3.8 as base

USER root

RUN echo "Installing git" \
    && apt-get update \
    && apt-get install -y build-essential git \
    && rm -rf /var/lib/apt/lists/*

FROM base

USER ${AIRFLOW_UID}

ARG AIRFLOW_HOME=/opt/airflow
ARG MELTANO_HOME=${AIRFLOW_HOME}/meltano

# Install meltano
RUN pip install 'meltano==1.89.0'

RUN mkdir ${MELTANO_HOME}
RUN mkdir ${MELTANO_HOME}/.meltano/

# Configure Meltano
ENV MELTANO_PROJECT_ROOT ${MELTANO_HOME}
ENV MELTANO_PROJECT_READONLY 1

# Install all plugins into the `.meltano` directory
ENV PIP_USER=false
COPY meltano.yml ${MELTANO_HOME}
RUN meltano install

# Pin `discovery.yml` manifest by copying cached version to project root
RUN cp -n ${MELTANO_HOME}/.meltano/cache/discovery.yml . 2>/dev/null || :

# Install any additional Airflow requirements
ENV PIP_USER=true
COPY orchestrate/requirements.txt .
RUN pip install -r requirements.txt

# Copy over remaining project files
COPY . .
