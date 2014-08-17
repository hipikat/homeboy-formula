#!stateconf -o yaml . jinja


{% from "homeboy/map.jinja" import users with context %}
{% for name, user in pillar.get('users', {}).items() if user.absent is not defined or not user.absent %}
  {% set home = user.get('home', "/home/%s" % name) %}

  # Install 'dotfiles' from a git repository
  {% if 'dotfiles' in user %}
    {% set dotfiles = user['dotfiles'] %}
    {% set dotfiles_dir = home ~ '/' ~ dotfiles.get('dir', '.dotfiles') %}
.Dotfiles git checkout for {{ name }}:
  git.latest:
    - name: {{ dotfiles['url'] }}
    - target: {{ dotfiles_dir }}
    - user: {{ name }}
  {% endif %}

  {% if 'install_cmd' in dotfiles %}
.Dotfiles install command for {{ name }}:
  cmd.wait:
    - name: {{ dotfiles['install_cmd'] }}
    - user: {{ name }}
    - cwd: {{ dotfiles_dir }}
    - watch:
      - git: .Dotfiles git checkout for {{ name }}
  {% endif %}

  # Install system packages for this user
  {% if 'uses_sys_packages' in user %}
.Install system packages for user {{ name }}:
  pkg.installed:
    - pkgs:
      {% for sys_pkg in user['uses_sys_packages'] %}
      - {{ sys_pkg }}
      {% endfor %}
  {% endif %}

  # Install system-Python packages for this user
  {% for py_pkg in user.get('uses_py_packages', []) %}
.Install system-Python package {{ py_pkg }} for {{ name }}:
  pkg.installed:
    - name: python-pip

  pip.installed:
    - name: {{ py_pkg }}
    - require:
      - pkg: .Install system-Python package {{ py_pkg }} for {{ name }}
  {% endfor %}

{% endfor %}