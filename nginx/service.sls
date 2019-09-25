# nginx.service
#
# Manages the nginx service.

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import nginx, sls_block with context %}
{%- from tplroot ~ '/libtofs.jinja' import files_switch with context %}

{% set service_function = {True:'running', False:'dead'}.get(nginx.service.enable) %}

include:
  {% if nginx.install_from_source %}
  - nginx.src
  {% else %}
  - nginx.pkg
  {% endif %}

{% if nginx.install_from_source %}
nginx_systemd_service_file:
  file.managed:
    - name: /lib/systemd/system/nginx.service
    - source: {{ files_switch(['nginx.service'],
                              'nginx_systemd_service_file'
                 )
              }}
{% endif %}

nginx_service:
  service.{{ service_function }}:
    {{ sls_block(nginx.service.opts) }}
    - name: {{ nginx.lookup.service }}
    - enable: {{ nginx.service.enable }}
    - require:
      {% if nginx.install_from_source %}
      - sls: nginx.src
      {% else %}
      - sls: nginx.pkg
      {% endif %}
    - listen:
      {% if nginx.install_from_source %}
      - cmd: nginx_install
      {% else %}
      - pkg: nginx_install
      {% endif %}

{% if nginx.limitnofile %}
/etc/systemd/system/nginx.service.d/limits.conf:
  file.managed:
    - makedirs: True
    - contents:
      - "[Service]"
      - "LimitNOFILE={{ nginx.limitnofile }}"

systemctl-reload-nginx:
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/nginx.service.d/limits.conf
{% endif %}