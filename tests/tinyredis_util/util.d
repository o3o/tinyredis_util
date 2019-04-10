module tests.tinyredis_util.util;

import unit_threaded;

import tinyredis_util.util;
import tinyredis : Redis;

@UnitTest void getdouble() {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", 3.14);
   redis.send("SET", "delete:me", 3.15);
   redis.get!string("delete_me").shouldEqual("3.14");
   redis.get!int("delete_me").shouldEqual(3);
   redis.get!double("delete_me").shouldEqual(3.14);
   redis.get!bool("delete_me").shouldBeTrue;

   redis.get!string("delete:me").shouldEqual("3.15");
   redis.get!int("delete:me").shouldEqual(3);
   redis.get!double("delete:me").shouldEqual(3.15);
   redis.get!bool("delete:me").shouldBeTrue;

   redis.send("SET", "delete_me", 0.0);
   redis.get!string("delete_me").shouldEqual("0");
   redis.get!int("delete_me").shouldEqual(0);
   redis.get!double("delete_me").shouldEqual(0.);
   redis.get!bool("delete_me").shouldBeFalse;
   redis.send("DEL", "delete_me");
   redis.get!double("delete_me").shouldEqual(0.);

   redis.send("SET", "not_a_num", double.nan);
   import std.math : isNaN;

   redis.get!double("not_a_num").isNaN.shouldBeTrue;
}

@UnitTest void getint() {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", 42);
   redis.get!string("delete_me").shouldEqual("42");
   redis.get!int("delete_me").shouldEqual(42);
   redis.get!uint("delete_me").shouldEqual(42);
   redis.get!long("delete_me").shouldEqual(42L);
   redis.get!double("delete_me").shouldEqual(42.);
   redis.get!bool("delete_me").shouldBeTrue;

   redis.send("SET", "delete_me", 0);
   redis.get!string("delete_me").shouldEqual("0");
   redis.get!int("delete_me").shouldEqual(0);
   redis.get!long("delete_me").shouldEqual(0L);
   redis.get!double("delete_me").shouldEqual(0.);
   redis.get!bool("delete_me").shouldBeFalse;

   redis.send("SET", "delete_me", -42);
   redis.get!string("delete_me").shouldEqual("-42");
   redis.get!int("delete_me").shouldEqual(-42);
   //redis.get!uint("delete_me").shouldEqual(42); overflow
   redis.get!long("delete_me").shouldEqual(-42L);
   redis.get!double("delete_me").shouldEqual(-42.);
   redis.get!bool("delete_me").shouldBeTrue;
}
@UnitTest void getnull() {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.get!string("none").shouldEqual("");
   redis.get!int("none").shouldEqual(0);
   redis.get!uint("none").shouldEqual(0);
   redis.get!long("none").shouldEqual(0L);
   redis.get!double("none").shouldEqual(0.);
   redis.get!bool("none").shouldBeFalse;
}

@UnitTest void getuint() {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "my_uint", cast(uint)42);
   redis.get!string("my_uint").shouldEqual("42");
   redis.get!uint("my_uint").shouldEqual(42);
   redis.get!int("my_uint").shouldEqual(42);
   redis.get!long("my_uint").shouldEqual(42L);
   redis.get!double("my_uint").shouldEqual(42.);
   redis.get!bool("my_uint").shouldBeTrue;
   redis.send("SET", "my_uint", cast(uint)0);
   redis.get!string("my_uint").shouldEqual("0");
   redis.get!int("my_uint").shouldEqual(0);
   redis.get!long("my_uint").shouldEqual(0L);
   redis.get!double("my_uint").shouldEqual(0.);
   redis.get!bool("my_uint").shouldBeFalse;
}

@UnitTest void getlong() {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", 42L);
   redis.get!string("delete_me").shouldEqual("42");
   redis.get!int("delete_me").shouldEqual(42);
   redis.get!long("delete_me").shouldEqual(42L);
   redis.get!double("delete_me").shouldEqual(42.);
   redis.get!bool("delete_me").shouldBeTrue;

   redis.send("SET", "delete_me", 0L);
   redis.get!string("delete_me").shouldEqual("0");
   redis.get!int("delete_me").shouldEqual(0);
   redis.get!long("delete_me").shouldEqual(0L);
   redis.get!double("delete_me").shouldEqual(0.);
   redis.get!bool("delete_me").shouldBeFalse;
}

@UnitTest void getbool() {
   Redis redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", true);
   redis.get!string("delete_me").shouldEqual("true");
   redis.get!int("delete_me").shouldEqual(1);
   redis.get!long("delete_me").shouldEqual(1L);
   redis.get!double("delete_me").shouldEqual(1.);
   redis.get!bool("delete_me").shouldBeTrue;

   redis.send("SET", "delete_me", false);
   redis.get!string("delete_me").shouldEqual("false");
   redis.get!int("delete_me").shouldEqual(0);
   redis.get!long("delete_me").shouldEqual(0L);
   redis.get!double("delete_me").shouldEqual(0.);
   redis.get!bool("delete_me").shouldBeFalse;
}

@UnitTest void getstring() {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", "true");
   redis.get!string("delete_me").shouldEqual("true");
   redis.get!int("delete_me").shouldEqual(1);
   redis.get!long("delete_me").shouldEqual(1L);
   redis.get!double("delete_me").shouldEqual(1.);
   redis.get!bool("delete_me").shouldBeTrue;

   redis.send("SET", "delete_me", "false");
   redis.get!string("delete_me").shouldEqual("false");
   redis.get!int("delete_me").shouldEqual(0);
   redis.get!long("delete_me").shouldEqual(0L);
   redis.get!double("delete_me").shouldEqual(0.);
   redis.get!bool("delete_me").shouldBeFalse;

   redis.send("SET", "delete_me", "cul");
   redis.get!string("delete_me").shouldEqual("cul");
   redis.get!int("delete_me").shouldEqual(0);
   redis.get!long("delete_me").shouldEqual(0L);
   redis.get!double("delete_me").shouldEqual(0.);
   redis.get!bool("delete_me").shouldBeFalse;

   redis.send("SET", "delete_me", "42");
   redis.get!string("delete_me").shouldEqual("42");
   redis.get!int("delete_me").shouldEqual(42);
   redis.get!long("delete_me").shouldEqual(42L);
   redis.get!double("delete_me").shouldEqual(42.);
   redis.get!bool("delete_me").shouldBeTrue;

   redis.send("SET", "delete_me", "3.14");
   redis.get!string("delete_me").shouldEqual("3.14");
   redis.get!int("delete_me").shouldEqual(3);
   redis.get!double("delete_me").shouldEqual(3.14);
   redis.get!bool("delete_me").shouldBeTrue;

   redis.send("SET", "delete_me", "3,14");
   redis.get!string("delete_me").shouldEqual("3,14");
   redis.get!int("delete_me").shouldEqual(0);
   redis.get!double("delete_me").shouldEqual(0.);
   redis.get!bool("delete_me").shouldBeFalse;
}

@UnitTest void gettime() {
   import std.datetime : DateTime;
   import std.datetime.systime : SysTime;

   auto redis = new Redis();
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   enum UT = 1_552_320_073;

   redis.send("SET", "ut", UT);
   auto expected = SysTime(DateTime(2019, 3, 11, 17, 01, 13));

   redis.get!SysTime("ut").shouldEqual(expected);

   redis.set!SysTime("ut1", expected);
   redis.get!long("ut1").shouldEqual(UT);
}

@UnitTest void respTobool() {
   Redis redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", true);
   redis.send("GET", "delete_me").respTo!string.shouldEqual("true");
   redis.send("GET", "delete_me").respTo!int.shouldEqual(1);
   redis.send("GET", "delete_me").respTo!long.shouldEqual(1L);
   redis.send("GET", "delete_me").respTo!double.shouldEqual(1.);
   redis.send("GET", "delete_me").respTo!bool.shouldBeTrue;

   redis.send("SET", "delete_me", false);
   redis.send("GET", "delete_me").respTo!string.shouldEqual("false");
   redis.send("GET", "delete_me").respTo!int.shouldEqual(0);
   redis.send("GET", "delete_me").respTo!long.shouldEqual(0L);
   redis.send("GET", "delete_me").respTo!double.shouldEqual(0.);
   redis.send("GET", "delete_me").respTo!bool.shouldBeFalse;
}

@UnitTest void srespToString() {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", "true");
   redis.send("GET", "delete_me").respTo!string.shouldEqual("true");
   redis.send("GET", "delete_me").respTo!int.shouldEqual(1);
   redis.send("GET", "delete_me").respTo!long.shouldEqual(1L);
   redis.send("GET", "delete_me").respTo!double.shouldEqual(1.);
   redis.send("GET", "delete_me").respTo!bool.shouldBeTrue;

   redis.send("SET", "delete_me", "false");
   redis.send("GET", "delete_me").respTo!string.shouldEqual("false");
   redis.send("GET", "delete_me").respTo!int.shouldEqual(0);
   redis.send("GET", "delete_me").respTo!long.shouldEqual(0L);
   redis.send("GET", "delete_me").respTo!double.shouldEqual(0.);
   redis.send("GET", "delete_me").respTo!bool.shouldBeFalse;

   redis.send("SET", "delete_me", "cul");
   redis.send("GET", "delete_me").respTo!string.shouldEqual("cul");
   redis.send("GET", "delete_me").respTo!int.shouldEqual(0);
   redis.send("GET", "delete_me").respTo!long.shouldEqual(0L);
   redis.send("GET", "delete_me").respTo!double.shouldEqual(0.);
   redis.send("GET", "delete_me").respTo!bool.shouldBeFalse;

   redis.send("SET", "delete_me", "42");
   redis.send("GET", "delete_me").respTo!string.shouldEqual("42");
   redis.send("GET", "delete_me").respTo!int.shouldEqual(42);
   redis.send("GET", "delete_me").respTo!long.shouldEqual(42L);
   redis.send("GET", "delete_me").respTo!double.shouldEqual(42.);
   redis.send("GET", "delete_me").respTo!bool.shouldBeTrue;

   redis.send("SET", "delete_me", "3.14");
   redis.send("GET", "delete_me").respTo!string.shouldEqual("3.14");
   redis.send("GET", "delete_me").respTo!int.shouldEqual(3);
   redis.send("GET", "delete_me").respTo!double.shouldEqual(3.14);
   redis.send("GET", "delete_me").respTo!bool.shouldBeTrue;

   redis.send("SET", "delete_me", "3,14");
   redis.send("GET", "delete_me").respTo!string.shouldEqual("3,14");
   redis.send("GET", "delete_me").respTo!int.shouldEqual(0);
   redis.send("GET", "delete_me").respTo!double.shouldEqual(0.);
   redis.send("GET", "delete_me").respTo!bool.shouldBeFalse;
}

@UnitTest void respToDouble() {
   auto redis = new Redis("localhost", 6379);
   redis.send("SELECT", 1);
   redis.send("FLUSHDB");

   redis.send("SET", "delete_me", 3.14);
   redis.send("GET", "delete_me").respTo!string.shouldEqual("3.14");
   redis.send("GET", "delete_me").respTo!int.shouldEqual(3);
   redis.send("GET", "delete_me").respTo!double.shouldEqual(3.14);
   redis.send("GET", "delete_me").respTo!bool.shouldBeTrue;

   redis.send("SET", "delete:me", 3.15);
   redis.send("GET", "delete:me").respTo!string.shouldEqual("3.15");
   redis.send("GET", "delete:me").respTo!int.shouldEqual(3);
   redis.send("GET", "delete:me").respTo!double.shouldEqual(3.15);
   redis.send("GET", "delete:me").respTo!bool.shouldBeTrue;

   redis.send("SET", "delete_me", 0.0);
   redis.send("GET", "delete_me").respTo!string.shouldEqual("0");
   redis.send("GET", "delete_me").respTo!int.shouldEqual(0);
   redis.send("GET", "delete_me").respTo!double.shouldEqual(0.);
   redis.send("GET", "delete_me").respTo!bool.shouldBeFalse;
   redis.send("DEL", "delete_me");
   redis.send("GET", "delete_me").respTo!double.shouldEqual(0.);

   redis.send("SET", "not_a_num", double.nan);
   import std.math : isNaN;
   redis.send("GET", "not_a_num").respTo!double.isNaN.shouldBeTrue;
}
