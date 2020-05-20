#!stateconf -o yaml . jinja


{% from "homeboy/map.jinja" import users with context %}
{% for name, user in pillar.get('users', {}).items() if user.absent is not defined or not user.absent %}
  {% set home = user.get('home', "/home/%s" % name) %}

  # Install 'dotfiles' from a git repository
  {% if 'dotfiles' in user %}

    {% set dotfiles = user['dotfiles'] %}
    {% set dotfiles_dir = home ~ '/' ~ dotfiles.get('dir', '.dotfiles') ~ '/' %}

.Dotfiles git checkout for {{ name }}:
  git.latest:
    - name: {{ dotfiles['url'] }}
    - target: {{ dotfiles_dir }}
    - runas: {{ name }}
    {% if 'deploy_key' in dotfiles %}
    - identity: {{ dotfiles['deploy_key'] }}
    {% endif %}

    {% if 'install_cmd' in dotfiles %}
.Dotfiles install command in {{ dotfiles_dir }}:
  cmd.wait:
    - name: {{ dotfiles['install_cmd'] }}
    - shell: /bin/bash
    - runas: {{ name }}
    - cwd: {{ dotfiles_dir }}
    - watch:
      - git: .Dotfiles git checkout for {{ name }}
    {% endif %}

  {% endif %}

  # Install system packages for this user
  {% if 'uses_system_packages' in user %}
.Install system packages for user {{ name }}:
  pkg.installed:
    - pkgs:
      {% for sys_pkg in user['uses_system_packages'] %}
      - {{ sys_pkg }}
      {% endfor %}
  {% endif %}

  # Install system-Python packages for this user
  {% for py_pkg in user.get('uses_python_packages', []) %}
.Install system-Python package {{ py_pkg }} for {{ name }}:
  pkg.installed:
    - name: python-pip

  pip.installed:
    - name: {{ py_pkg }}
    - require:
      - pkg: .Install system-Python package {{ py_pkg }} for {{ name }}
  {% endfor %}

{% endfor %}
