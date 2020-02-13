CREATE OR REPLACE FUNCTION v8.plv8_require()
RETURNS VOID AS $$
  plv8.elog(NOTICE, 'INIT plv8_require()');

  moduleCache = {};

  load = function(key, source) {
    var module = {exports: {}};
    eval("(function(module, exports) {" + source + "; })")(module, module.exports);

    //-- store in cache
    moduleCache[key] = module.exports;
    return module.exports;
  };

  require = function(module) {
    if(moduleCache[module])
      return moduleCache[module];

    var rows = plv8.execute(
      "select source from v8.modules where module = $1",
      [module]
    );

    if(rows.length === 0) {
      plv8.elog(NOTICE, 'Could not load module: ' + module);
      return null;
    }

    return load(module, rows[0].source);
  };

  //-- Grab modules worth auto-loading at context start and let them cache
  var query = 'select module, source from v8.modules where autoload = true';
  plv8.execute(query).forEach(function(row) {
    plv8.elog(NOTICE, 'Autoloading module: ' + row.module);
    load(row.module, row.source);
  });
$$ LANGUAGE plv8;
