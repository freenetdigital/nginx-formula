# nginx.confd
#
# Manages creation of extra config filesin /etc/nginx/conf.d

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ '/map.jinja' import nginx, sls_block with context %}
{%- from tplroot ~ '/libtofs.jinja' import files_switch with context %}

nginx_confd_dir:
  file.directory:
    {{ sls_block(nginx.servers.dir_opts) }}
    - name: {{ nginx.lookup.confd_dir }}

{% for snippet, config in nginx.confd.items() %}
nginx_snippet_{{ snippet }}:
  file.managed:
    - name: {{ nginx.lookup.confd_dir ~ '/' ~ snippet }}
    - source: {{ files_switch([ snippet, 'server.conf' ],
                              'nginx_snippet_file_managed'
                 )
              }}
    - template: jinja
    - context:
        config: {{ config|json() }}
{% endfor %}
