module tinyredis_util.util;

import tinyredis : Redis, Response;

version (unittest) import unit_threaded;

/**
 * Set a Redis variable.
 *
 * Params:
 *  redis = Database
 *  key = Variable name
 *  value = Variable value
 */
void set(T)(Redis redis, string key, T value) {
   import std.datetime.systime : SysTime;

   static if (is(T == SysTime)) {
      long unixTime = value.toUnixTime!long;
      redis.send("SET", key, unixTime);
   } else {
      redis.send("SET", key, value);
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
   import std.conv : to;
   import std.string : isNumeric;
   import std.datetime.systime : SysTime;

   static if (is(T == double) || (is(T == float))) {
      string reply = redis.send!string("GET", key);
      if (reply.isNumeric) {
         return reply.to!(T);
      } else {
         return reply == "true" ? 1. : 0.;
      }
   } else static if ((is(T == int)) || (is(T == long)) || (is(T == uint)) || (is(T == ulong))) {
      string reply = redis.send!string("GET", key);
      if (reply.isNumeric) {
         return reply.to!(double)
            .to!(T);
      } else {
         return reply == "true" ? 1 : 0;
      }
   } else static if (is(T == bool)) {
      string reply = redis.send!string("GET", key);
      if (reply.isNumeric) {
         return reply.to!(double) != 0.;
      } else {
         return reply == "true";
      }
   } else static if (is(T == SysTime)) {
      long unixTime = redis.get!long(key);
      return SysTime.fromUnixTime(unixTime);
   } else {
      return redis.send!(T)("GET", key);
   }
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

/**
* Copy a structure into Redis variables.
  *
  * Examples:
  * If the structure is:
  * --------------------
  * struct Foo {
  *   int intParm;
  *   string stringParm;
  *  bool is60Hz
  * }
  * --------------------
  *
  * Then
  * --------------------
  * Foo foo;
  * copyToRedis!Foo(foo, redis, "f:")
  * --------------------
  *
 * set these redis variables:
  *
  * - f:int_parm
  * - f:string_parm
  * - f:is60_hz ATTENTION between letter and number does not add underscore
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
   condition:
      "aa", loggerName : "DD", visible : true, noOfIteration : 42, duration : 19.64, lists : ["a", "b"]
   };

   t.copyToRedis!DummyData(redis, "cu_");
   redis.get!string("cu_condition").shouldEqual("aa");
   redis.get!string("cu_logger_name").shouldEqual("DD");
   redis.get!bool("cu_visible").shouldBeTrue;
   redis.get!int("cu_no_of_iteration").shouldEqual(42);
   redis.get!double("cu_duration").shouldEqual(19.64);
   // gli array sono ignorati
   redis.get!string("lists").shouldEqual("");

   redis.get!string("adasdadwerwerwerwer").shouldEqual("");
}

/**
 * Copy the values of the Redis variables into a structure.
  *
  * The names of the redis variables to be used are the names of the members in snake_case with optional prefix.
  *
  * If T is a structure:
 * --------------------
 * struct Foo {
 *   int fooName;
 * }
 * --------------------
 *
 *Then `copyToStruct` copies the value of the variable `<prefix>foo_name` to foo.fooName
 *
 *
 * Params:
  * redis = Database from which to read the variables
  * target = Structure that receives the values
  * prefix = Prefix to be added to the variable names
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
   dummy.condition.should == "aa";
   dummy.loggerName.shouldEqual("DD");
   dummy.noOfIteration.shouldEqual(42);
   dummy.duration.shouldEqual(19.64);
   dummy.lists.length.shouldEqual(0);
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

@("snake")
unittest {
   "ABCD".camelCaseToSnake.shouldEqual("abcd");
   "A0CD".camelCaseToSnake.shouldEqual("a0_cd");
   "aBcD".camelCaseToSnake.shouldEqual("a_bc_d");
   "aBcDE".camelCaseToSnake.shouldEqual("a_bc_de");
   "a0CDe".camelCaseToSnake.shouldEqual("a0_c_de");
   "abCDe".camelCaseToSnake.shouldEqual("ab_c_de");
   "aBc1".camelCaseToSnake.shouldEqual("a_bc1");
   "xABy".camelCaseToSnake.shouldEqual("x_a_by");
   "caccaPipiPuzzetta".camelCaseToSnake.shouldEqual("cacca_pipi_puzzetta");
   "vacuum0PThreshold".camelCaseToSnake.shouldEqual("vacuum0_p_threshold");
   "vacuum0PressThreshold".camelCaseToSnake.shouldEqual("vacuum0_press_threshold");
   "".camelCaseToSnake.shouldEqual("");

   "cop3pAvg".camelCaseToSnake.shouldEqual("cop3p_avg");
   "cop3p".camelCaseToSnake.shouldEqual("cop3p");
   "vSupply3pMeas".camelCaseToSnake.shouldEqual("v_supply3p_meas");
   "pDisAtTCondSp".camelCaseToSnake.shouldEqual("p_dis_at_t_cond_sp");
}
