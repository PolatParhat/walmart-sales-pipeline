{#
  Overrides dbt's default schema-naming behavior.

  By default, dbt appends a model's `+schema` config onto the connection's
  target schema (e.g. +schema: GOLD under a target schema of SILVER would
  create SILVER_GOLD, not GOLD). That's fine when you want environment
  prefixing (dev_gold, prod_gold), but this project's schemas are fixed
  medallion layers (RAW/SILVER/GOLD), not environment-qualified - so a
  model with +schema: GOLD should land in GOLD, literally.

  This is dbt Labs' own documented override for exactly this case:
  https://docs.getdbt.com/docs/build/custom-schemas
#}
{% macro generate_schema_name(custom_schema_name, node) %}
  {% set default_schema = target.schema %}
  {% if custom_schema_name is none %}
      {{default_schema}}
  {%else%}
    {{custom_schema_name | trim}}
  {% endif %}

{% endmacro %}