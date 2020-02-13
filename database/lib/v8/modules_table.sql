CREATE TABLE v8.modules (
  module TEXT UNIQUE PRIMARY KEY CHECK(length(module) < 255) DEFAULT 'Unnamed',
  autoload bool DEFAULT true,
  source TEXT
);


INSERT INTO v8.modules (module, autoload, source) VALUES ('utils', true, $MODULE$
var Utils = {
  insertOne: function(sql, args) {
    args = args || []
    sql = sql + ' ON CONFLICT DO NOTHING RETURNING *'
    var result = null
    try {
      result = plv8.execute(sql, args)[0]
    } catch (e) {
      Utils.log(e.message, e.stack)
      throw e
    }
    return result
  },
  selectOne: function(sql, args) {
    args = args || []
    var result = null
    try {
      result = plv8.execute(sql, args)[0]
    } catch (e) {
      Utils.log(e.message, e.stack)
      throw e
    }
    return result
  },
  run: function(sql, args) {
    args = args || []
    sql = 'SELECT ' + sql
    var result = plv8.execute(sql, args)
    //-- When running a func you get back something like this
    //-- [{"create_team":{"name":"Acme",...}}]
    var obj = result[0]
    var vals = []
    for (var key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        vals.push(obj[key])
      }
    }
    return vals[0]
  },
  log: function() {
    var overflow = []
    var maxL = 900
    var args = Array.prototype.slice.call(arguments, 0).map(function(arg, i) {
      if (arg instanceof Object) arg = JSON.stringify(arg)
      if (typeof arg == 'string' && arg.length > maxL) {
        overflow[i] = arg.substring(maxL)
        arg = arg.substring(0, maxL)
      }
      return arg
    })
    plv8.elog.apply(this, [WARNING].concat(args))
    if (overflow.length) Utils.log.apply(this, overflow)
  }
}

module.exports = Utils

$MODULE$);
