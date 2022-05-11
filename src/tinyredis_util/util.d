module tinyredis_util.util;

import tinyredis : Redis, Response;
import std.datetime.systime : SysTime;
import std.experimental.logger;
/**
 * Copy the value stored at the source key to the destination key.
 *
 * Removes the destination key before copying the value to it (REPLACE option)
 */
void copy(Redis redis, in string source, in string destination) {
   redis.send("COPY", source, destination, "REPLACE");
}
unittest {
   import std.conv : to;
   Redis redis = new Redis();
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");
   redis.set!string("dolly", "sheep");
   redis.copy("dolly", "clone");
   assert(redis.get!string("clone") == "sheep");
}

/**
 * Set a Redis variable.
 *
 * Params:
 *  redis = Database
 *  key = Variable name
 *  value = Variable value
 */
void set(T)(Redis redis, string key, T value) {
   static if (is(T == SysTime)) {
      long unixTime = value.toUnixTime!long;
      redis.send("SET", key, unixTime);
   } else {
      redis.send("SET", key, value);
   }
}
unittest {
   import std.conv : to;
   Redis redis = new Redis();
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");
   enum Status {
      idle,
      setET,
      openBypass
   }
   redis.set!string("status", Status.openBypass.to!string());
   assert(redis.get!string("status") == "openBypass");
   assert(redis.get!string("status").to!Status == Status.openBypass);
}


/**
 * psetex works exactly like SETEX with the sole difference that the expire time is specified in milliseconds instead of seconds.
 *
 * Params:
 *  redis = Database
 *  key = Variable name
 *  milliseconds = Expire time
 *  value = Variable value
 */
void psetex(T)(Redis redis, string key, int milliseconds, T value) {
   redis.send("PSETEX", key, milliseconds, value);
}

/**
 * Set key to hold the string value and set key to timeout after a given number of seconds
 *
 * Params:
 *  redis = Database
 *  key = Variable name
 *  seconds = Expire time
 *  value = Variable value
 */
void setex(T)(Redis redis, string key, int seconds, T value) {
   redis.send("SETEX", key, seconds, value);
}

/**
 * Returns the value associated with field in the hash stored at key.
 *
 * Params:
 *  redis = Database
 *  key = Hash name
 *  field = Field name
 */
T hget(T)(Redis redis, string key, string field) {
   static if (commonType!T) {
      string reply = redis.send!string("HGET", key, field);
      return conv!(T)(reply);
   } else {
      return redis.send!(T)("HGET", key, field);
   }
}

/**
 * Get a Redis variable
 *
 * Params:
 *  redis = Database
 *  key = Variable name
 */
T get(T)(Redis redis, string key) {
   static if (commonType!T) {
      string reply = redis.send!string("GET", key);
      return conv!(T)(reply);
   } else {
      return redis.send!(T)("GET", key);
   }
}

unittest {
   Redis redis = new Redis();
   redis.send("select", 1);
   redis.send("flushdb");
   redis.send("HMSET", "hh", "a", 10, "b", 11);
   redis.send("HSET", "hh", "c", "12");
   int h0 = redis.hget!int("hh", "a");
   assert(h0 == 10);

   string h1 = redis.hget!string("hh", "c");
   assert(h1 == "12");
   string h2 = redis.hget!string("hh", "b");
   assert(h2 == "11");
}

template commonType(T) {
   enum commonType = (is(T == bool) || is(T == float) || is(T == double) || is(T == short) || is(T == int)
            || is(T == long) || is(T == uint) || is(T == ulong) || is(T == string) || is(T == SysTime));
}

/**
 * Convert a string into T type.
 *
 *
 */
T conv(T)(string input) if (commonType!T) {
   import std.conv : to;
   import std.string : isNumeric;
   import std.datetime : DateTime;

   static if (is(T == double) || (is(T == float))) {
      if (input.isNumeric) {
         return input.to!(T);
      } else {
         return input == "true" ? 1. : 0.;
      }
   } else static if ((is(T == int)) || (is(T == long)) || (is(T == uint)) || (is(T == ulong))) {
      if (input.isNumeric) {
         return input.to!(double)
            .to!(T);
      } else {
         return input == "true" ? 1 : 0;
      }
   } else static if (is(T == bool)) {
      if (input.isNumeric) {
         return input.to!(double) != 0.;
      } else {
         return input == "true" || input == "t";
      }
   } else static if (is(T == string)) {
      return input;
   } else static if (is(T == SysTime)) {
      if (input.isNumeric) {
         long unixTime = input.to!(double)
            .to!long;
         return SysTime.fromUnixTime(unixTime);
      } else {
         warning("empty datatime");
         return SysTime(DateTime(1970, 1, 1, 1, 1, 1));
      }
   } else {
      assert(false);
   }
}

@("getdouble")
unittest {
   import std.datetime : DateTime;

   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", 3.14);
   redis.send("SET", "delete:me", 3.15);
   assert(redis.get!string("delete_me") == "3.14");
   assert(redis.get!int("delete_me") == 3);
   assert(redis.get!double("delete_me") == 3.14);
   assert(redis.get!bool("delete_me"));

   assert(redis.get!string("delete:me") == "3.15");
   assert(redis.get!int("delete:me") == 3);
   assert(redis.get!double("delete:me") == 3.15);
   assert(redis.get!bool("delete:me"));

   redis.send("SET", "delete_me", 0.0);
   assert(redis.get!string("delete_me") == "0");
   assert(redis.get!int("delete_me") == 0);
   assert(redis.get!double("delete_me") == 0.);
   assert(!redis.get!bool("delete_me"));

   redis.send("DEL", "delete_me");
   assert(redis.get!double("delete_me") == 0.);

   redis.send("SET", "not_a_num", double.nan);

   import std.math : isNaN;

   assert(redis.get!double("not_a_num").isNaN);

   enum UT = 1_552_320_073;
   redis.send("SET", "ut", UT);
   auto expected = SysTime(DateTime(2019, 3, 11, 17, 01, 13));

   assert(redis.get!SysTime("ut") == expected);
}

@("getint")
unittest {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", 42);
   assert(redis.get!string("delete_me") == "42");
   assert(redis.get!int("delete_me") == 42);
   assert(redis.get!uint("delete_me") == 42);
   assert(redis.get!long("delete_me") == 42L);
   assert(redis.get!ulong("delete_me") == 42uL);
   assert(redis.get!size_t("delete_me") == 42uL);
   assert(redis.get!double("delete_me") == 42.);
   assert(redis.get!bool("delete_me"));

   redis.send("SET", "delete_me", 0);
   assert(redis.get!string("delete_me") == "0");
   assert(redis.get!int("delete_me") == 0);
   assert(redis.get!long("delete_me") == 0L);
   assert(redis.get!double("delete_me") == 0.);
   assert(!redis.get!bool("delete_me"));

   redis.send("SET", "delete_me", -42);
   assert(redis.get!string("delete_me") == "-42");
   assert(redis.get!int("delete_me") == -42);
   //redis.get!uint("delete_me") == 42); overflow
   assert(redis.get!long("delete_me") == -42L);
   assert(redis.get!double("delete_me") == -42.);
   assert(redis.get!bool("delete_me"));
}

@("getnull")
unittest {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   assert(redis.get!string("none") == "");
   assert(redis.get!int("none") == 0);
   assert(redis.get!uint("none") == 0);
   assert(redis.get!long("none") == 0L);
   assert(redis.get!double("none") == 0.);
   assert(!redis.get!bool("none"));
}

@("getuint")
unittest {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "my_uint", cast(uint)42);
   assert(redis.get!string("my_uint") == "42");
   assert(redis.get!uint("my_uint") == 42);
   assert(redis.get!int("my_uint") == 42);
   assert(redis.get!long("my_uint") == 42L);
   assert(redis.get!double("my_uint") == 42.);
   assert(redis.get!bool("my_uint"));

   redis.send("SET", "my_uint", cast(uint)0);
   assert(redis.get!string("my_uint") == "0");
   assert(redis.get!int("my_uint") == 0);
   assert(redis.get!long("my_uint") == 0L);
   assert(redis.get!double("my_uint") == 0.);
   assert(!redis.get!bool("my_uint"));
}

@("getlong")
unittest {
   auto redis = new Redis("localhost", 6379);

   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", 42L);
   assert(redis.get!string("delete_me") == "42");
   assert(redis.get!int("delete_me") == 42);
   assert(redis.get!long("delete_me") == 42L);
   assert(redis.get!double("delete_me") == 42.);
   assert(redis.get!bool("delete_me"));

   redis.send("SET", "delete_me", 0L);
   assert(redis.get!string("delete_me") == "0");
   assert(redis.get!int("delete_me") == 0);
   assert(redis.get!long("delete_me") == 0L);
   assert(redis.get!double("delete_me") == 0.);
   assert(!redis.get!bool("delete_me"));
}

@("getbool")
unittest {
   Redis redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", true);
   assert(redis.get!string("delete_me") == "true");
   assert(redis.get!int("delete_me") == 1);
   assert(redis.get!long("delete_me") == 1L);
   assert(redis.get!double("delete_me") == 1.);
   assert(redis.get!bool("delete_me"));

   redis.send("SET", "delete_me", false);
   assert(redis.get!string("delete_me") == "false");
   assert(redis.get!int("delete_me") == 0);
   assert(redis.get!long("delete_me") == 0L);
   assert(redis.get!double("delete_me") == 0.);
   assert(!redis.get!bool("delete_me"));

   redis.send("SET", "bool_as_string", "true");
   assert(redis.get!bool("bool_as_string"));
   redis.send("SET", "bool_as_string", "t");
   assert(redis.get!bool("bool_as_string"));
   redis.send("SET", "bool_as_string", "f");
   assert(!redis.get!bool("bool_as_string"));
}

@("getstring")
unittest {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", "true");
   assert(redis.get!string("delete_me") == "true");
   assert(redis.get!int("delete_me") == 1);
   assert(redis.get!long("delete_me") == 1L);
   assert(redis.get!double("delete_me") == 1.);
   assert(redis.get!bool("delete_me"));

   redis.send("SET", "delete_me", "false");
   assert(redis.get!string("delete_me") == "false");
   assert(redis.get!int("delete_me") == 0);
   assert(redis.get!long("delete_me") == 0L);
   assert(redis.get!double("delete_me") == 0.);
   assert(!redis.get!bool("delete_me"));

   redis.send("SET", "delete_me", "cul");
   assert(redis.get!string("delete_me") == "cul");
   assert(redis.get!int("delete_me") == 0);
   assert(redis.get!long("delete_me") == 0L);
   assert(redis.get!double("delete_me") == 0.);
   assert(!redis.get!bool("delete_me"));

   redis.send("SET", "delete_me", "42");
   assert(redis.get!string("delete_me") == "42");
   assert(redis.get!int("delete_me") == 42);
   assert(redis.get!long("delete_me") == 42L);
   assert(redis.get!double("delete_me") == 42.);
   assert(redis.get!bool("delete_me"));

   redis.send("SET", "delete_me", "3.14");
   assert(redis.get!string("delete_me") == "3.14");
   assert(redis.get!int("delete_me") == 3);
   assert(redis.get!double("delete_me") == 3.14);
   assert(redis.get!bool("delete_me"));

   redis.send("SET", "delete_me", "3,14");
   assert(redis.get!string("delete_me") == "3,14");
   assert(redis.get!int("delete_me") == 0);
   assert(redis.get!double("delete_me") == 0.);
   assert(!redis.get!bool("delete_me"));
}

@("gettime")
unittest {
   import std.datetime : DateTime;
   import std.datetime.systime : SysTime;

   auto redis = new Redis();
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   enum UT = 1_552_320_073;
   redis.send("SET", "ut", UT);
   auto expected = SysTime(DateTime(2019, 3, 11, 17, 01, 13));

   assert(redis.get!SysTime("ut") == expected);

   redis.set!SysTime("ut1", expected);
   assert(redis.get!long("ut1") == UT);
   redis.send("SET", "ut", "");
   auto epoch = SysTime(DateTime(1970, 1, 1, 1, 1, 1));
   assert(redis.get!SysTime("ut") == epoch);
}
/**
 * Returns the bit value at offset in the string value stored at key.
 */
bool getBit(Redis redis, string key, uint offset) {
   return redis.send("GETBIT", key, offset).toBool;
}

/**
 * Sets or clears the bit at offset in the string value stored at key.
 * The bit is either set or cleared depending on value, which can be either 0 or 1.
 *
 * Params:
 *  redis = Database
 *  key = Key
 *  offset = Bit to set or reset
 */
void setBit(Redis redis, string key, uint offset, bool value) {
   redis.send("SETBIT", key, offset, value ? 1 : 0);
}

/**
 * Tests and sets (sets to 1) the bit.
 *
 * Internally use `SETBIT` function.
 */
bool bts(Redis redis, string key, uint bitnum) {
   bool b = redis.getBit(key, bitnum);
   redis.send("SETBIT", key, bitnum, 1);
   return b;
}

/**
 * Tests and resets (sets to 0) the bit.
 *
 * Internally use `SETBIT` function.
 */
bool btr(Redis redis, string key, uint bitnum) {
   bool b = redis.getBit(key, bitnum);
   redis.send("SETBIT", key, bitnum, 0);
   return b;
}

///
unittest {
   auto redis = new Redis();
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.setBit("bf", 3, true);
   assert(redis.getBit("bf", 3));

   redis.setBit("bf", 0, true);
   assert(redis.getBit("bf", 0));
   assert(!redis.getBit("bf", 1));
   assert(!redis.getBit("bf", 2));
   assert(redis.getBit("bf", 3));

   redis.btr("bf", 0);
   assert(!redis.getBit("bf", 0));

   redis.btr("bf", 3);
   assert(!redis.getBit("bf", 3));
}

/**
 * Safe convert Response
 */
T respTo(T)(Response response) {
   import std.conv : to;
   import std.string : isNumeric;
   import std.datetime.systime : SysTime;

   static if (is(T == double) || (is(T == float))) {
      string reply = response.toString;
      if (reply.isNumeric) {
         return reply.to!(T);
      } else {
         return reply == "true" ? 1. : 0.;
      }
   } else static if ((is(T == int)) || (is(T == long)) || (is(T == uint)) || (is(T == ulong))) {
      string reply = response.toString;
      if (reply.isNumeric) {
         return reply.to!(double)
            .to!(T);
      } else {
         return reply == "true" ? 1 : 0;
      }
   } else static if (is(T == bool)) {
      string reply = response.toString;
      if (reply.isNumeric) {
         return reply.to!(double) != 0.;
      } else {
         return reply == "true";
      }
   } else {
      return response.toString.to!T;
   }
}

@("respTobool")
unittest {
   Redis redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", true);
   assert(redis.send("GET", "delete_me").respTo!string == "true");
   assert(redis.send("GET", "delete_me").respTo!int == 1);
   assert(redis.send("GET", "delete_me").respTo!long == 1L);
   assert(redis.send("GET", "delete_me").respTo!double == 1.);
   assert(redis.send("GET", "delete_me").respTo!bool);

   redis.send("SET", "delete_me", false);
   assert(redis.send("GET", "delete_me").respTo!string == "false");
   assert(redis.send("GET", "delete_me").respTo!int == 0);
   assert(redis.send("GET", "delete_me").respTo!long == 0L);
   assert(redis.send("GET", "delete_me").respTo!double == 0.);
   assert(!redis.send("GET", "delete_me").respTo!bool);
}

@("respToString")
unittest {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", "true");
   assert(redis.send("GET", "delete_me").respTo!string == "true");
   assert(redis.send("GET", "delete_me").respTo!int == 1);
   assert(redis.send("GET", "delete_me").respTo!long == 1L);
   assert(redis.send("GET", "delete_me").respTo!double == 1.);
   assert(redis.send("GET", "delete_me").respTo!bool);

   redis.send("SET", "delete_me", "false");
   assert(redis.send("GET", "delete_me").respTo!string == "false");
   assert(redis.send("GET", "delete_me").respTo!int == 0);
   assert(redis.send("GET", "delete_me").respTo!long == 0L);
   assert(redis.send("GET", "delete_me").respTo!double == 0.);
   assert(!redis.send("GET", "delete_me").respTo!bool);

   redis.send("SET", "delete_me", "cul");
   assert(redis.send("GET", "delete_me").respTo!string == "cul");
   assert(redis.send("GET", "delete_me").respTo!int == 0);
   assert(redis.send("GET", "delete_me").respTo!long == 0L);
   assert(redis.send("GET", "delete_me").respTo!double == 0.);
   assert(!redis.send("GET", "delete_me").respTo!bool);

   redis.send("SET", "delete_me", "42");
   assert(redis.send("GET", "delete_me").respTo!string == "42");
   assert(redis.send("GET", "delete_me").respTo!int == 42);
   assert(redis.send("GET", "delete_me").respTo!long == 42L);
   assert(redis.send("GET", "delete_me").respTo!double == 42.);
   assert(redis.send("GET", "delete_me").respTo!bool);

   redis.send("SET", "delete_me", "3.14");
   assert(redis.send("GET", "delete_me").respTo!string == "3.14");
   assert(redis.send("GET", "delete_me").respTo!int == 3);
   assert(redis.send("GET", "delete_me").respTo!double == 3.14);
   assert(redis.send("GET", "delete_me").respTo!bool);

   redis.send("SET", "delete_me", "3,14");
   assert(redis.send("GET", "delete_me").respTo!string == "3,14");
   assert(redis.send("GET", "delete_me").respTo!int == 0);
   assert(redis.send("GET", "delete_me").respTo!double == 0.);
   assert(!redis.send("GET", "delete_me").respTo!bool);
}

@("respToDouble")
unittest {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", 3.14);
   assert(redis.send("GET", "delete_me").respTo!string == "3.14");
   assert(redis.send("GET", "delete_me").respTo!int == 3);
   assert(redis.send("GET", "delete_me").respTo!double == 3.14);
   assert(redis.send("GET", "delete_me").respTo!bool);

   redis.send("SET", "delete:me", 3.15);
   assert(redis.send("GET", "delete:me").respTo!string == "3.15");
   assert(redis.send("GET", "delete:me").respTo!int == 3);
   assert(redis.send("GET", "delete:me").respTo!double == 3.15);
   assert(redis.send("GET", "delete:me").respTo!bool);

   redis.send("SET", "delete_me", 0.0);
   assert(redis.send("GET", "delete_me").respTo!string == "0");
   assert(redis.send("GET", "delete_me").respTo!int == 0);
   assert(redis.send("GET", "delete_me").respTo!double == 0.);
   assert(!redis.send("GET", "delete_me").respTo!bool);
   redis.send("DEL", "delete_me");
   assert(redis.send("GET", "delete_me").respTo!double == 0.);

   redis.send("SET", "not_a_num", double.nan);
   import std.math : isNaN;

   assert(redis.send("GET", "not_a_num").respTo!double.isNaN);
}

/**
 * Copy a structure into Redis variables.
 *
 * Examples:
 * If the structure is:
 * ```
 * struct Foo {
 *   int intParm;
 *   string stringParm;
 *   bool is60Hz
 * }
 * ```
 *
 * Then
 * ```
 * Foo foo;
 * copyToRedis!Foo(foo, redis, "f:")
 * ```
 *
 * set these redis variables:
 * $(LIST
 *   * f:int_parm
 *   * f:string_parm
 *   * f:is60_hz ATTENTION between letter and number does not add underscore
 * )
 *
 * Params:
 * source = Structure to copy
 * target = Database in which to copy the structure
 * prefix = Prefix to be added to the structure members
 */
void copyToRedis(T)(T source, Redis target, string prefix) {
   import std.traits : hasMember, isBasicType, isSomeString, FieldNameTuple;

   foreach (member; FieldNameTuple!T) {
      auto value = __traits(getMember, source, member);
      string name = member.camelCaseToSnake;
      /*
       * l'assegnazione:
       * target[k ~ member] = value;
       * e' eseguita a compile-time, se si omette static si ha un errore tentando di assegnare `let` ad un Parm
       */
      static if (isBasicType!(typeof(value)) || isSomeString!(typeof(value))) {
         target.set(prefix ~ name, value);
      }
   }
}

@("test_copy_pre")
unittest {
   Redis redis = new Redis("localhost", 6379);

   struct DummyData {
      string condition;
      string loggerName;
      int noOfIteration;
      double duration;
      bool visible;
      string[] lists;
   }

   DummyData t = {
      condition: "aa", loggerName: "DD", visible: true, noOfIteration: 42, duration: 19.64, lists: ["a", "b"]
   };

   t.copyToRedis!DummyData(redis, "cu_");
   assert(redis.get!string("cu_condition") == "aa");
   assert(redis.get!string("cu_logger_name") == "DD");
   assert(redis.get!bool("cu_visible"));
   assert(redis.get!int("cu_no_of_iteration") == 42);
   assert(redis.get!double("cu_duration") == 19.64);
   // gli array sono ignorati
   assert(redis.get!string("lists") == "");

   assert(redis.get!string("adasdadwerwerwerwer") == "");
}

/**
 * Copy the values of the Redis variables into a structure.
 *
 * The names of the redis variables to be used are the names of the members in snake_case with optional prefix.
 *
 * If T is a structure:
 * ```
 * struct Foo {
 *   int fooName;
 * }
 * ```
 *
 * Then `copyToStruct` copies the value of the variable `<prefix>foo_name` to foo.fooName
 *
 *
 * Params:
 *  redis = Database from which to read the variables
 *  target = Structure that receives the values
 *  prefix = Prefix to be added to the variable names
 */
void copyToStruct(T)(Redis redis, ref T target, string prefix) {
   import std.traits : hasMember;

   foreach (member; __traits(allMembers, T)) {
      auto m = __traits(getMember, target, member);
      string name = member.camelCaseToSnake;

      static if (is(typeof(m) == int)) {
         __traits(getMember, target, member) = redis.get!int(prefix ~ name);
      } else static if (is(typeof(m) == long)) {
         __traits(getMember, target, member) = redis.get!long(prefix ~ name);
      } else static if (is(typeof(m) == double)) {
         __traits(getMember, target, member) = redis.get!double(prefix ~ name);
      } else static if (is(typeof(m) == bool)) {
         __traits(getMember, target, member) = redis.get!bool(prefix ~ name);
      } else static if (is(typeof(m) == string)) {
         __traits(getMember, target, member) = redis.get!string(prefix ~ name);
      }
   }
}

///
@("copy2struct")
unittest {
   Redis redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");
   redis.set!string("cu_condition", "aa");
   redis.set!string("cu_logger_name", "DD");
   redis.set!bool("cu_visible", true);
   redis.set!int("cu_no_of_iteration", 42);
   redis.set!double("cu_duration", 19.64);

   struct DummyData {
      string condition;
      string loggerName;
      int noOfIteration;
      double duration;
      bool visible;
      string[] lists;
   }

   DummyData dummy;
   redis.copyToStruct(dummy, "cu_");
   assert(dummy.condition == "aa");
   assert(dummy.loggerName == "DD");
   assert(dummy.noOfIteration == 42);
   assert(dummy.duration == 19.64);
   assert(dummy.lists.length == 0);
}

/**
 * Convert a lower camelcase string to snake case.
 * We can't use regex to match at compile-time so we'll iterate through the string and convert it manually.
 *
 * See_Also:
 * [see util.d](https://github.com/jjpatel/dhtags)
 */
string camelCaseToSnake(in string s) @safe pure {
   import std.array : join;
   import std.range : enumerate;
   import std.algorithm : map;
   import std.ascii : isUpper, isLower, isDigit;
   import std.string : toLower;
   import std.conv : to;

   return s.enumerate.map!((t) {
      if (isUpper(t.value)) {
         if (t.index > 0 && (isLower(s[t.index - 1]) || isDigit(s[t.index - 1]) || (t.index < s.length - 1 && isLower(s[t.index + 1])))) {
            return "_" ~ t.value.toLower.to!string;
         } else {
            return t.value.toLower.to!string;
         }
      } else {
         return t.value.to!string;
      }
   }).join;
}

///
@("snake")
unittest {
   assert("ABCD".camelCaseToSnake == "abcd");
   assert("A0CD".camelCaseToSnake == "a0_cd");
   assert("aBcD".camelCaseToSnake == "a_bc_d");
   assert("aBcDE".camelCaseToSnake == "a_bc_de");
   assert("a0CDe".camelCaseToSnake == "a0_c_de");
   assert("abCDe".camelCaseToSnake == "ab_c_de");
   assert("aBc1".camelCaseToSnake == "a_bc1");
   assert("xABy".camelCaseToSnake == "x_a_by");
   assert("caccaPipiPuzzetta".camelCaseToSnake == "cacca_pipi_puzzetta");
   assert("vacuum0PThreshold".camelCaseToSnake == "vacuum0_p_threshold");
   assert("vacuum0PressThreshold".camelCaseToSnake == "vacuum0_press_threshold");
   assert("".camelCaseToSnake == "");

   assert("cop3pAvg".camelCaseToSnake == "cop3p_avg");
   assert("cop3p".camelCaseToSnake == "cop3p");
   assert("vSupply3pMeas".camelCaseToSnake == "v_supply3p_meas");
   assert("pDisAtTCondSp".camelCaseToSnake == "p_dis_at_t_cond_sp");
   assert("res8r1".camelCaseToSnake == "res8r1");
   assert("pid00run".camelCaseToSnake == "pid00run");
}
