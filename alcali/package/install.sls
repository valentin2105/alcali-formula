# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import alcali with context %}

{% if alcali.config.db_backend == 'mysql' %}
{% set db_connector = 'mysqlclient' %}
{% set db_requirements = {
    'RedHat': ['mysql-devel', 'python3-devel'],
    'Debian': ['default-libmysqlclient-dev', 'python3-dev'],
}.get(grains.os_family) %}
{% elif alcali.config.db_backend == 'postgres' %}
{% set db_connector = 'psycopg2' %}
{% set db_requirements = {
    'RedHat': ['mysql-devel', 'python3-devel'],
    'Debian': ['libpq-devel', 'python3-dev'],
}.get(grains.os_family) %}
{% endif %}

alcali-package-install-pkg-installed:
  pkg.installed:
    - pkgs:
      - git
      - gcc
      - virtualenv
      - python-pip
      - python3-pip
      - python3-virtualenv

{% for pkg in db_requirements %}
{{ pkg }}:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}

alcali-package-install-git-latest:
  git.latest:
    - name: {{ alcali.deploy.repository }}
    - target: {{ alcali.deploy.directory }}/code
    - user: {{ alcali.deploy.user }}
    - branch: {{ alcali.deploy.branch }}

alcali-package-install-virtualenv-managed:
  virtualenv.managed:
    - name: {{ alcali.deploy.directory }}/.venv
    - user: {{ alcali.deploy.user }}
    - python: {{ alcali.deploy.runtime }}
    - system_site_packages: False
    - requirements: {{ alcali.deploy.directory }}/code/requirements/prod.txt
    - require:
      - git: alcali-package-install-git-latest

alcali-package-install-pip-installed:
  pip.installed:
    - name: {{ db_connector }}
    - user: {{ alcali.deploy.user }}
    - cwd: {{ alcali.deploy.directory }}
    - bin_env: {{ alcali.deploy.directory }}/.venv
    - require:
      - virtualenv: alcali-package-install-virtualenv-managed