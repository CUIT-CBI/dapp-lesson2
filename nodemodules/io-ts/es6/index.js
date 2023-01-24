var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
import { left, right } from 'fp-ts/lib/Either';
/**
 * @since 1.0.0
 */
var Type = /** @class */ (function () {
    function Type(
    /** a unique name for this codec */
    name, 
    /** a custom type guard */
    is, 
    /** succeeds if a value of type I can be decoded to a value of type A */
    validate, 
    /** converts a value of type A to a value of type O */
    encode) {
        this.name = name;
        this.is = is;
        this.validate = validate;
        this.encode = encode;
        this.decode = this.decode.bind(this);
    }
    Type.prototype.pipe = function (ab, name) {
        var _this = this;
        if (name === void 0) { name = "pipe(" + this.name + ", " + ab.name + ")"; }
        return new Type(name, ab.is, function (i, c) { return _this.validate(i, c).chain(function (a) { return ab.validate(a, c); }); }, this.encode === identity && ab.encode === identity ? identity : function (b) { return _this.encode(ab.encode(b)); });
    };
    Type.prototype.asDecoder = function () {
        return this;
    };
    Type.prototype.asEncoder = function () {
        return this;
    };
    /** a version of `validate` with a default context */
    Type.prototype.decode = function (i) {
        return this.validate(i, [{ key: '', type: this, actual: i }]);
    };
    return Type;
}());
export { Type };
/**
 * @since 1.0.0
 */
export var identity = function (a) { return a; };
/**
 * @since 1.0.0
 */
export var getFunctionName = function (f) {
    return f.displayName || f.name || "<function" + f.length + ">";
};
/**
 * @since 1.0.0
 */
export var getContextEntry = function (key, decoder) { return ({ key: key, type: decoder }); };
/**
 * @since 1.0.0
 */
export var appendContext = function (c, key, decoder, actual) {
    var len = c.length;
    var r = Array(len + 1);
    for (var i = 0; i < len; i++) {
        r[i] = c[i];
    }
    r[len] = { key: key, type: decoder, actual: actual };
    return r;
};
/**
 * @since 1.0.0
 */
export var failures = left;
/**
 * @since 1.0.0
 */
export var failure = function (value, context, message) {
    return failures([{ value: value, context: context, message: message }]);
};
/**
 * @since 1.0.0
 */
export var success = right;
var pushAll = function (xs, ys) {
    var l = ys.length;
    for (var i = 0; i < l; i++) {
        xs.push(ys[i]);
    }
};
var getIsCodec = function (tag) { return function (codec) { return codec._tag === tag; }; };
var isUnknownCodec = getIsCodec('UnknownType');
// tslint:disable-next-line: deprecation
var isAnyCodec = getIsCodec('AnyType');
var isInterfaceCodec = getIsCodec('InterfaceType');
var isPartialCodec = getIsCodec('PartialType');
//
// basic types
//
/**
 * @since 1.0.0
 */
var NullType = /** @class */ (function (_super) {
    __extends(NullType, _super);
    function NullType() {
        var _this = _super.call(this, 'null', function (u) { return u === null; }, function (u, c) { return (_this.is(u) ? success(u) : failure(u, c)); }, identity) || this;
        _this._tag = 'NullType';
        return _this;
    }
    return NullType;
}(Type));
export { NullType };
/**
 * @alias `null`
 * @since 1.0.0
 */
export var nullType = new NullType();
/**
 * @since 1.0.0
 */
var UndefinedType = /** @class */ (function (_super) {
    __extends(UndefinedType, _super);
    function UndefinedType() {
        var _this = _super.call(this, 'undefined', function (u) { return u === void 0; }, function (u, c) { return (_this.is(u) ? success(u) : failure(u, c)); }, identity) || this;
        _this._tag = 'UndefinedType';
        return _this;
    }
    return UndefinedType;
}(Type));
export { UndefinedType };
var undefinedType = new UndefinedType();
/**
 * @since 1.2.0
 */
var VoidType = /** @class */ (function (_super) {
    __extends(VoidType, _super);
    function VoidType() {
        var _this = _super.call(this, 'void', undefinedType.is, undefinedType.validate, identity) || this;
        _this._tag = 'VoidType';
        return _this;
    }
    return VoidType;
}(Type));
export { VoidType };
/**
 * @alias `void`
 * @since 1.2.0
 */
export var voidType = new VoidType();
/**
 * @since 1.5.0
 */
var UnknownType = /** @class */ (function (_super) {
    __extends(UnknownType, _super);
    function UnknownType() {
        var _this = _super.call(this, 'unknown', function (_) { return true; }, success, identity) || this;
        _this._tag = 'UnknownType';
        return _this;
    }
    return UnknownType;
}(Type));
export { UnknownType };
/**
 * @since 1.5.0
 */
export var unknown = new UnknownType();
/**
 * @since 1.0.0
 */
var StringType = /** @class */ (function (_super) {
    __extends(StringType, _super);
    function StringType() {
        var _this = _super.call(this, 'string', function (u) { return typeof u === 'string'; }, function (u, c) { return (_this.is(u) ? success(u) : failure(u, c)); }, identity) || this;
        _this._tag = 'StringType';
        return _this;
    }
    return StringType;
}(Type));
export { StringType };
/**
 * @since 1.0.0
 */
export var string = new StringType();
/**
 * @since 1.0.0
 */
var NumberType = /** @class */ (function (_super) {
    __extends(NumberType, _super);
    function NumberType() {
        var _this = _super.call(this, 'number', function (u) { return typeof u === 'number'; }, function (u, c) { return (_this.is(u) ? success(u) : failure(u, c)); }, identity) || this;
        _this._tag = 'NumberType';
        return _this;
    }
    return NumberType;
}(Type));
export { NumberType };
/**
 * @since 1.0.0
 */
export var number = new NumberType();
/**
 * @since 1.0.0
 */
var BooleanType = /** @class */ (function (_super) {
    __extends(BooleanType, _super);
    function BooleanType() {
        var _this = _super.call(this, 'boolean', function (u) { return typeof u === 'boolean'; }, function (u, c) { return (_this.is(u) ? success(u) : failure(u, c)); }, identity) || this;
        _this._tag = 'BooleanType';
        return _this;
    }
    return BooleanType;
}(Type));
export { BooleanType };
/**
 * @since 1.0.0
 */
export var boolean = new BooleanType();
/**
 * @since 1.0.0
 */
var AnyArrayType = /** @class */ (function (_super) {
    __extends(AnyArrayType, _super);
    function AnyArrayType() {
        var _this = _super.call(this, 'UnknownArray', Array.isArray, function (u, c) { return (_this.is(u) ? success(u) : failure(u, c)); }, identity) || this;
        _this._tag = 'AnyArrayType';
        return _this;
    }
    return AnyArrayType;
}(Type));
export { AnyArrayType };
/**
 * @since 1.7.1
 */
export var UnknownArray = new AnyArrayType();
/**
 * @since 1.0.0
 */
var AnyDictionaryType = /** @class */ (function (_super) {
    __extends(AnyDictionaryType, _super);
    function AnyDictionaryType() {
        var _this = _super.call(this, 'UnknownRecord', function (u) { return u !== null && typeof u === 'object'; }, function (u, c) { return (_this.is(u) ? success(u) : failure(u, c)); }, identity) || this;
        _this._tag = 'AnyDictionaryType';
        return _this;
    }
    return AnyDictionaryType;
}(Type));
export { AnyDictionaryType };
/**
 * @since 1.7.1
 */
export var UnknownRecord = new AnyDictionaryType();
/**
 * @since 1.0.0
 * @deprecated
 */
var FunctionType = /** @class */ (function (_super) {
    __extends(FunctionType, _super);
    function FunctionType() {
        var _this = _super.call(this, 'Function', 
        // tslint:disable-next-line:strict-type-predicates
        function (u) { return typeof u === 'function'; }, function (u, c) { return (_this.is(u) ? success(u) : failure(u, c)); }, identity) || this;
        _this._tag = 'FunctionType';
        return _this;
    }
    return FunctionType;
}(Type));
export { FunctionType };
/**
 * @since 1.0.0
 * @deprecated
 */
// tslint:disable-next-line: deprecation
export var Function = new FunctionType();
/**
 * @since 1.0.0
 */
var RefinementType = /** @class */ (function (_super) {
    __extends(RefinementType, _super);
    function RefinementType(name, is, validate, encode, type, predicate) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.type = type;
        _this.predicate = predicate;
        _this._tag = 'RefinementType';
        return _this;
    }
    return RefinementType;
}(Type));
export { RefinementType };
/**
 * @since 1.8.1
 */
export var brand = function (codec, predicate, name) {
    // tslint:disable-next-line: deprecation
    return refinement(codec, predicate, name);
};
/**
 * A branded codec representing an integer
 * @since 1.8.1
 */
export var Int = brand(number, function (n) { return Number.isInteger(n); }, 'Int');
/**
 * @since 1.0.0
 */
var LiteralType = /** @class */ (function (_super) {
    __extends(LiteralType, _super);
    function LiteralType(name, is, validate, encode, value) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.value = value;
        _this._tag = 'LiteralType';
        return _this;
    }
    return LiteralType;
}(Type));
export { LiteralType };
/**
 * @since 1.0.0
 */
export var literal = function (value, name) {
    if (name === void 0) { name = JSON.stringify(value); }
    var is = function (u) { return u === value; };
    return new LiteralType(name, is, function (u, c) { return (is(u) ? success(value) : failure(u, c)); }, identity, value);
};
/**
 * @since 1.0.0
 */
var KeyofType = /** @class */ (function (_super) {
    __extends(KeyofType, _super);
    function KeyofType(name, is, validate, encode, keys) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.keys = keys;
        _this._tag = 'KeyofType';
        return _this;
    }
    return KeyofType;
}(Type));
export { KeyofType };
var hasOwnProperty = Object.prototype.hasOwnProperty;
/**
 * @since 1.0.0
 */
export var keyof = function (keys, name) {
    if (name === void 0) { name = Object.keys(keys)
        .map(function (k) { return JSON.stringify(k); })
        .join(' | '); }
    var is = function (u) { return string.is(u) && hasOwnProperty.call(keys, u); };
    return new KeyofType(name, is, function (u, c) { return (is(u) ? success(u) : failure(u, c)); }, identity, keys);
};
/**
 * @since 1.0.0
 */
var RecursiveType = /** @class */ (function (_super) {
    __extends(RecursiveType, _super);
    function RecursiveType(name, is, validate, encode, runDefinition) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.runDefinition = runDefinition;
        _this._tag = 'RecursiveType';
        return _this;
    }
    Object.defineProperty(RecursiveType.prototype, "type", {
        get: function () {
            return this.runDefinition();
        },
        enumerable: true,
        configurable: true
    });
    return RecursiveType;
}(Type));
export { RecursiveType };
/**
 * @since 1.0.0
 */
export var recursion = function (name, definition) {
    var cache;
    var runDefinition = function () {
        if (!cache) {
            cache = definition(Self);
            cache.name = name;
        }
        return cache;
    };
    var Self = new RecursiveType(name, function (u) { return runDefinition().is(u); }, function (u, c) { return runDefinition().validate(u, c); }, function (a) { return runDefinition().encode(a); }, runDefinition);
    return Self;
};
/**
 * @since 1.0.0
 */
var ArrayType = /** @class */ (function (_super) {
    __extends(ArrayType, _super);
    function ArrayType(name, is, validate, encode, type) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.type = type;
        _this._tag = 'ArrayType';
        return _this;
    }
    return ArrayType;
}(Type));
export { ArrayType };
/**
 * @since 1.0.0
 */
export var array = function (codec, name) {
    if (name === void 0) { name = "Array<" + codec.name + ">"; }
    return new ArrayType(name, function (u) { return UnknownArray.is(u) && u.every(codec.is); }, function (u, c) {
        return UnknownArray.validate(u, c).chain(function (us) {
            var len = us.length;
            var as = us;
            var errors = [];
            var _loop_1 = function (i) {
                var ui = us[i];
                codec.validate(ui, appendContext(c, String(i), codec, ui)).fold(function (e) { return pushAll(errors, e); }, function (ai) {
                    if (ai !== ui) {
                        if (as === us) {
                            as = us.slice();
                        }
                        as[i] = ai;
                    }
                });
            };
            for (var i = 0; i < len; i++) {
                _loop_1(i);
            }
            return errors.length > 0 ? failures(errors) : success(as);
        });
    }, codec.encode === identity ? identity : function (a) { return a.map(codec.encode); }, codec);
};
/**
 * @since 1.0.0
 */
var InterfaceType = /** @class */ (function (_super) {
    __extends(InterfaceType, _super);
    function InterfaceType(name, is, validate, encode, props) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.props = props;
        _this._tag = 'InterfaceType';
        return _this;
    }
    return InterfaceType;
}(Type));
export { InterfaceType };
var getNameFromProps = function (props) {
    return Object.keys(props)
        .map(function (k) { return k + ": " + props[k].name; })
        .join(', ');
};
var useIdentity = function (codecs) {
    for (var i = 0; i < codecs.length; i++) {
        if (codecs[i].encode !== identity) {
            return false;
        }
    }
    return true;
};
var getInterfaceTypeName = function (props) {
    return "{ " + getNameFromProps(props) + " }";
};
/**
 * @alias `interface`
 * @since 1.0.0
 */
export var type = function (props, name) {
    if (name === void 0) { name = getInterfaceTypeName(props); }
    var keys = Object.keys(props);
    var types = keys.map(function (key) { return props[key]; });
    var len = keys.length;
    return new InterfaceType(name, function (u) {
        if (!UnknownRecord.is(u)) {
            return false;
        }
        for (var i = 0; i < len; i++) {
            var k = keys[i];
            if (!hasOwnProperty.call(u, k) || !types[i].is(u[k])) {
                return false;
            }
        }
        return true;
    }, function (u, c) {
        return UnknownRecord.validate(u, c).chain(function (o) {
            var a = o;
            var errors = [];
            var _loop_2 = function (i) {
                var k = keys[i];
                if (!hasOwnProperty.call(a, k)) {
                    if (a === o) {
                        a = __assign({}, o);
                    }
                    a[k] = a[k];
                }
                var ak = a[k];
                var type_1 = types[i];
                type_1.validate(ak, appendContext(c, k, type_1, ak)).fold(function (e) { return pushAll(errors, e); }, function (vak) {
                    if (vak !== ak) {
                        /* istanbul ignore next */
                        if (a === o) {
                            a = __assign({}, o);
                        }
                        a[k] = vak;
                    }
                });
            };
            for (var i = 0; i < len; i++) {
                _loop_2(i);
            }
            return errors.length > 0 ? failures(errors) : success(a);
        });
    }, useIdentity(types)
        ? identity
        : function (a) {
            var s = __assign({}, a);
            for (var i = 0; i < len; i++) {
                var k = keys[i];
                var encode = types[i].encode;
                if (encode !== identity) {
                    s[k] = encode(a[k]);
                }
            }
            return s;
        }, props);
};
/**
 * @since 1.0.0
 */
var PartialType = /** @class */ (function (_super) {
    __extends(PartialType, _super);
    function PartialType(name, is, validate, encode, props) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.props = props;
        _this._tag = 'PartialType';
        return _this;
    }
    return PartialType;
}(Type));
export { PartialType };
var getPartialTypeName = function (inner) {
    return "Partial<" + inner + ">";
};
/**
 * @since 1.0.0
 */
export var partial = function (props, name) {
    if (name === void 0) { name = getPartialTypeName(getInterfaceTypeName(props)); }
    var keys = Object.keys(props);
    var types = keys.map(function (key) { return props[key]; });
    var len = keys.length;
    return new PartialType(name, function (u) {
        if (!UnknownRecord.is(u)) {
            return false;
        }
        for (var i = 0; i < len; i++) {
            var k = keys[i];
            var uk = u[k];
            if (uk !== undefined && !props[k].is(uk)) {
                return false;
            }
        }
        return true;
    }, function (u, c) {
        return UnknownRecord.validate(u, c).chain(function (o) {
            var a = o;
            var errors = [];
            var _loop_3 = function (i) {
                var k = keys[i];
                var ak = a[k];
                var type_2 = props[k];
                type_2.validate(ak, appendContext(c, k, type_2, ak)).fold(function (e) {
                    if (ak !== undefined) {
                        pushAll(errors, e);
                    }
                }, function (vak) {
                    if (vak !== ak) {
                        /* istanbul ignore next */
                        if (a === o) {
                            a = __assign({}, o);
                        }
                        a[k] = vak;
                    }
                });
            };
            for (var i = 0; i < len; i++) {
                _loop_3(i);
            }
            return errors.length > 0 ? failures(errors) : success(a);
        });
    }, useIdentity(types)
        ? identity
        : function (a) {
            var s = __assign({}, a);
            for (var i = 0; i < len; i++) {
                var k = keys[i];
                var ak = a[k];
                if (ak !== undefined) {
                    s[k] = types[i].encode(ak);
                }
            }
            return s;
        }, props);
};
/**
 * @since 1.0.0
 */
var DictionaryType = /** @class */ (function (_super) {
    __extends(DictionaryType, _super);
    function DictionaryType(name, is, validate, encode, domain, codomain) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.domain = domain;
        _this.codomain = codomain;
        _this._tag = 'DictionaryType';
        return _this;
    }
    return DictionaryType;
}(Type));
export { DictionaryType };
var isObject = function (r) { return Object.prototype.toString.call(r) === '[object Object]'; };
/**
 * @since 1.7.1
 */
export var record = function (domain, codomain, name) {
    if (name === void 0) { name = "{ [K in " + domain.name + "]: " + codomain.name + " }"; }
    return new DictionaryType(name, function (u) {
        if (!UnknownRecord.is(u)) {
            return false;
        }
        if (!isUnknownCodec(codomain) && !isAnyCodec(codomain) && !isObject(u)) {
            return false;
        }
        return Object.keys(u).every(function (k) { return domain.is(k) && codomain.is(u[k]); });
    }, function (u, c) {
        return UnknownRecord.validate(u, c).chain(function (o) {
            if (!isUnknownCodec(codomain) && !isAnyCodec(codomain) && !isObject(o)) {
                return failure(u, c);
            }
            var a = {};
            var errors = [];
            var keys = Object.keys(o);
            var len = keys.length;
            var changed = false;
            var _loop_4 = function (i) {
                var k = keys[i];
                var ok = o[k];
                domain.validate(k, appendContext(c, k, domain, k)).fold(function (e) { return pushAll(errors, e); }, function (vk) {
                    changed = changed || vk !== k;
                    k = vk;
                    codomain.validate(ok, appendContext(c, k, codomain, ok)).fold(function (e) { return pushAll(errors, e); }, function (vok) {
                        changed = changed || vok !== ok;
                        a[k] = vok;
                    });
                });
            };
            for (var i = 0; i < len; i++) {
                _loop_4(i);
            }
            return errors.length > 0 ? failures(errors) : success((changed ? a : o));
        });
    }, domain.encode === identity && codomain.encode === identity
        ? identity
        : function (a) {
            var s = {};
            var keys = Object.keys(a);
            var len = keys.length;
            for (var i = 0; i < len; i++) {
                var k = keys[i];
                s[String(domain.encode(k))] = codomain.encode(a[k]);
            }
            return s;
        }, domain, codomain);
};
/**
 * @since 1.0.0
 */
var UnionType = /** @class */ (function (_super) {
    __extends(UnionType, _super);
    function UnionType(name, is, validate, encode, types) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.types = types;
        _this._tag = 'UnionType';
        return _this;
    }
    return UnionType;
}(Type));
export { UnionType };
var getUnionName = function (codecs) {
    return '(' + codecs.map(function (type) { return type.name; }).join(' | ') + ')';
};
/**
 * @since 1.0.0
 */
export var union = function (codecs, name) {
    if (name === void 0) { name = getUnionName(codecs); }
    var index = getIndex(codecs);
    if (index !== undefined && codecs.length > 0) {
        var tag_1 = index[0], groups_1 = index[1];
        var len_1 = groups_1.length;
        var find_1 = function (value) {
            for (var i = 0; i < len_1; i++) {
                if (groups_1[i].indexOf(value) !== -1) {
                    return i;
                }
            }
            return undefined;
        };
        // tslint:disable-next-line: deprecation
        return new TaggedUnionType(name, function (u) {
            if (!UnknownRecord.is(u)) {
                return false;
            }
            var i = find_1(u[tag_1]);
            return i !== undefined ? codecs[i].is(u) : false;
        }, function (u, c) {
            return UnknownRecord.validate(u, c).chain(function (r) {
                var i = find_1(r[tag_1]);
                if (i === undefined) {
                    return failure(u, c);
                }
                var codec = codecs[i];
                return codec.validate(r, appendContext(c, String(i), codec, r));
            });
        }, useIdentity(codecs)
            ? identity
            : function (a) {
                var i = find_1(a[tag_1]);
                if (i === undefined) {
                    // https://github.com/gcanti/io-ts/pull/305
                    throw new Error("no codec found to encode value in union codec " + name);
                }
                else {
                    return codecs[i].encode(a);
                }
            }, codecs, tag_1);
    }
    else {
        return new UnionType(name, function (u) { return codecs.some(function (type) { return type.is(u); }); }, function (u, c) {
            var errors = [];
            for (var i = 0; i < codecs.length; i++) {
                var codec = codecs[i];
                var r = codec
                    .validate(u, appendContext(c, String(i), codec, u))
                    .fold(function (e) { return pushAll(errors, e); }, success);
                if (r !== undefined) {
                    return r;
                }
            }
            return failures(errors);
        }, useIdentity(codecs)
            ? identity
            : function (a) {
                for (var _i = 0, codecs_1 = codecs; _i < codecs_1.length; _i++) {
                    var codec = codecs_1[_i];
                    if (codec.is(a)) {
                        return codec.encode(a);
                    }
                }
                // https://github.com/gcanti/io-ts/pull/305
                throw new Error("no codec found to encode value in union type " + name);
            }, codecs);
    }
};
/**
 * @since 1.0.0
 */
var IntersectionType = /** @class */ (function (_super) {
    __extends(IntersectionType, _super);
    function IntersectionType(name, is, validate, encode, types) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.types = types;
        _this._tag = 'IntersectionType';
        return _this;
    }
    return IntersectionType;
}(Type));
export { IntersectionType };
var mergeAll = function (base, us) {
    var r = base;
    for (var i = 0; i < us.length; i++) {
        var u = us[i];
        if (u !== base) {
            // `u` contains a prismatic value or is the result of a stripping combinator
            if (r === base) {
                r = Object.assign({}, u);
                continue;
            }
            for (var k in u) {
                if (u[k] !== base[k] || !r.hasOwnProperty(k)) {
                    r[k] = u[k];
                }
            }
        }
    }
    return r;
};
export function intersection(codecs, name) {
    if (name === void 0) { name = "(" + codecs.map(function (type) { return type.name; }).join(' & ') + ")"; }
    var len = codecs.length;
    return new IntersectionType(name, function (u) { return codecs.every(function (type) { return type.is(u); }); }, codecs.length === 0
        ? success
        : function (u, c) {
            var us = [];
            var errors = [];
            for (var i = 0; i < len; i++) {
                var codec = codecs[i];
                codec.validate(u, appendContext(c, String(i), codec, u)).fold(function (e) { return pushAll(errors, e); }, function (a) { return us.push(a); });
            }
            return errors.length > 0 ? failures(errors) : success(mergeAll(u, us));
        }, codecs.length === 0 ? identity : function (a) { return mergeAll(a, codecs.map(function (codec) { return codec.encode(a); })); }, codecs);
}
/**
 * @since 1.0.0
 */
var TupleType = /** @class */ (function (_super) {
    __extends(TupleType, _super);
    function TupleType(name, is, validate, encode, types) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.types = types;
        _this._tag = 'TupleType';
        return _this;
    }
    return TupleType;
}(Type));
export { TupleType };
export function tuple(codecs, name) {
    if (name === void 0) { name = "[" + codecs.map(function (type) { return type.name; }).join(', ') + "]"; }
    var len = codecs.length;
    return new TupleType(name, function (u) { return UnknownArray.is(u) && u.length === len && codecs.every(function (type, i) { return type.is(u[i]); }); }, function (u, c) {
        return UnknownArray.validate(u, c).chain(function (us) {
            var as = us.length > len ? us.slice(0, len) : us; // strip additional components
            var errors = [];
            var _loop_5 = function (i) {
                var a = us[i];
                var type_3 = codecs[i];
                type_3.validate(a, appendContext(c, String(i), type_3, a)).fold(function (e) { return pushAll(errors, e); }, function (va) {
                    if (va !== a) {
                        /* istanbul ignore next */
                        if (as === us) {
                            as = us.slice();
                        }
                        as[i] = va;
                    }
                });
            };
            for (var i = 0; i < len; i++) {
                _loop_5(i);
            }
            return errors.length > 0 ? failures(errors) : success(as);
        });
    }, useIdentity(codecs) ? identity : function (a) { return codecs.map(function (type, i) { return type.encode(a[i]); }); }, codecs);
}
/**
 * @since 1.0.0
 */
var ReadonlyType = /** @class */ (function (_super) {
    __extends(ReadonlyType, _super);
    function ReadonlyType(name, is, validate, encode, type) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.type = type;
        _this._tag = 'ReadonlyType';
        return _this;
    }
    return ReadonlyType;
}(Type));
export { ReadonlyType };
/**
 * @since 1.0.0
 */
export var readonly = function (codec, name) {
    if (name === void 0) { name = "Readonly<" + codec.name + ">"; }
    return new ReadonlyType(name, codec.is, function (u, c) {
        return codec.validate(u, c).map(function (x) {
            if (process.env.NODE_ENV !== 'production') {
                return Object.freeze(x);
            }
            return x;
        });
    }, codec.encode === identity ? identity : codec.encode, codec);
};
/**
 * @since 1.0.0
 */
var ReadonlyArrayType = /** @class */ (function (_super) {
    __extends(ReadonlyArrayType, _super);
    function ReadonlyArrayType(name, is, validate, encode, type) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.type = type;
        _this._tag = 'ReadonlyArrayType';
        return _this;
    }
    return ReadonlyArrayType;
}(Type));
export { ReadonlyArrayType };
/**
 * @since 1.0.0
 */
export var readonlyArray = function (codec, name) {
    if (name === void 0) { name = "ReadonlyArray<" + codec.name + ">"; }
    var arrayType = array(codec);
    return new ReadonlyArrayType(name, arrayType.is, function (u, c) {
        return arrayType.validate(u, c).map(function (x) {
            if (process.env.NODE_ENV !== 'production') {
                return Object.freeze(x);
            }
            return x;
        });
    }, arrayType.encode, codec);
};
/**
 * Strips additional properties
 * @since 1.0.0
 */
export var strict = function (props, name) {
    return exact(type(props), name);
};
/**
 * @since 1.3.0
 * @deprecated
 */
var TaggedUnionType = /** @class */ (function (_super) {
    __extends(TaggedUnionType, _super);
    function TaggedUnionType(name, 
    // tslint:disable-next-line: deprecation
    is, 
    // tslint:disable-next-line: deprecation
    validate, 
    // tslint:disable-next-line: deprecation
    encode, codecs, tag) {
        var _this = _super.call(this, name, is, validate, encode, codecs) /* istanbul ignore next */ // <= workaround for https://github.com/Microsoft/TypeScript/issues/13455
         || this;
        _this.tag = tag;
        return _this;
    }
    return TaggedUnionType;
}(UnionType));
export { TaggedUnionType };
/**
 * Use `union` instead
 *
 * @since 1.3.0
 * @deprecated
 */
export var taggedUnion = function (tag, codecs, name
// tslint:disable-next-line: deprecation
) {
    if (name === void 0) { name = getUnionName(codecs); }
    var U = union(codecs, name);
    // tslint:disable-next-line: deprecation
    if (U instanceof TaggedUnionType) {
        return U;
    }
    else {
        console.warn("[io-ts] Cannot build a tagged union for " + name + ", returning a de-optimized union");
        // tslint:disable-next-line: deprecation
        return new TaggedUnionType(name, U.is, U.validate, U.encode, codecs, tag);
    }
};
/**
 * @since 1.1.0
 */
var ExactType = /** @class */ (function (_super) {
    __extends(ExactType, _super);
    function ExactType(name, is, validate, encode, type) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.type = type;
        _this._tag = 'ExactType';
        return _this;
    }
    return ExactType;
}(Type));
export { ExactType };
var getProps = function (codec) {
    switch (codec._tag) {
        case 'RefinementType':
        case 'ReadonlyType':
            return getProps(codec.type);
        case 'InterfaceType':
        case 'StrictType':
        case 'PartialType':
            return codec.props;
        case 'IntersectionType':
            return codec.types.reduce(function (props, type) { return Object.assign(props, getProps(type)); }, {});
    }
};
var stripKeys = function (o, props) {
    var keys = Object.getOwnPropertyNames(o);
    var shouldStrip = false;
    var r = {};
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        if (!hasOwnProperty.call(props, key)) {
            shouldStrip = true;
        }
        else {
            r[key] = o[key];
        }
    }
    return shouldStrip ? r : o;
};
var getExactTypeName = function (codec) {
    if (isInterfaceCodec(codec)) {
        return "{| " + getNameFromProps(codec.props) + " |}";
    }
    else if (isPartialCodec(codec)) {
        return getPartialTypeName("{| " + getNameFromProps(codec.props) + " |}");
    }
    return "Exact<" + codec.name + ">";
};
/**
 * Strips additional properties
 * @since 1.1.0
 */
export var exact = function (codec, name) {
    if (name === void 0) { name = getExactTypeName(codec); }
    var props = getProps(codec);
    return new ExactType(name, codec.is, function (u, c) {
        return UnknownRecord.validate(u, c).chain(function () { return codec.validate(u, c).fold(left, function (a) { return success(stripKeys(a, props)); }); });
    }, function (a) { return codec.encode(stripKeys(a, props)); }, codec);
};
export { nullType as null };
export { undefinedType as undefined };
/**
 * Use `UnknownArray` instead
 * @deprecated
 */
export { UnknownArray as Array };
/**
 * Use `type` instead
 * @deprecated
 */
export { type as interface };
export { voidType as void };
/**
 * @since 1.0.0
 * @deprecated
 */
export var getValidationError /* istanbul ignore next */ = function (value, context) { return ({
    value: value,
    context: context
}); };
/**
 * @since 1.0.0
 * @deprecated
 */
export var getDefaultContext /* istanbul ignore next */ = function (decoder) { return [
    { key: '', type: decoder }
]; };
/**
 * @since 1.0.0
 * @deprecated
 */
var NeverType = /** @class */ (function (_super) {
    __extends(NeverType, _super);
    function NeverType() {
        var _this = _super.call(this, 'never', function (_) { return false; }, function (u, c) { return failure(u, c); }, 
        /* istanbul ignore next */
        function () {
            throw new Error('cannot encode never');
        }) || this;
        _this._tag = 'NeverType';
        return _this;
    }
    return NeverType;
}(Type));
export { NeverType };
/**
 * @since 1.0.0
 * @deprecated
 */
// tslint:disable-next-line: deprecation
export var never = new NeverType();
/**
 * @since 1.0.0
 * @deprecated
 */
var AnyType = /** @class */ (function (_super) {
    __extends(AnyType, _super);
    function AnyType() {
        var _this = _super.call(this, 'any', function (_) { return true; }, success, identity) || this;
        _this._tag = 'AnyType';
        return _this;
    }
    return AnyType;
}(Type));
export { AnyType };
/**
 * Use `unknown` instead
 * @since 1.0.0
 * @deprecated
 */
// tslint:disable-next-line: deprecation
export var any = new AnyType();
/**
 * Use `UnknownRecord` instead
 * @since 1.0.0
 * @deprecated
 */
export var Dictionary = UnknownRecord;
/**
 * @since 1.0.0
 * @deprecated
 */
var ObjectType = /** @class */ (function (_super) {
    __extends(ObjectType, _super);
    function ObjectType() {
        var _this = _super.call(this, 'object', UnknownRecord.is, UnknownRecord.validate, identity) || this;
        _this._tag = 'ObjectType';
        return _this;
    }
    return ObjectType;
}(Type));
export { ObjectType };
/**
 * Use `UnknownRecord` instead
 * @since 1.0.0
 * @deprecated
 */
// tslint:disable-next-line: deprecation
export var object = new ObjectType();
/**
 * Use `brand` instead
 * @since 1.0.0
 * @deprecated
 */
export function refinement(codec, predicate, name) {
    if (name === void 0) { name = "(" + codec.name + " | " + getFunctionName(predicate) + ")"; }
    return new RefinementType(name, function (u) { return codec.is(u) && predicate(u); }, function (i, c) { return codec.validate(i, c).chain(function (a) { return (predicate(a) ? success(a) : failure(a, c)); }); }, codec.encode, codec, predicate);
}
/**
 * Use `Int` instead
 * @since 1.0.0
 * @deprecated
 */
// tslint:disable-next-line: deprecation
export var Integer = refinement(number, Number.isInteger, 'Integer');
/**
 * Use `record` instead
 * @since 1.0.0
 * @deprecated
 */
export var dictionary = record;
/**
 * @since 1.0.0
 * @deprecated
 */
var StrictType = /** @class */ (function (_super) {
    __extends(StrictType, _super);
    function StrictType(name, 
    // tslint:disable-next-line: deprecation
    is, 
    // tslint:disable-next-line: deprecation
    validate, 
    // tslint:disable-next-line: deprecation
    encode, props) {
        var _this = _super.call(this, name, is, validate, encode) || this;
        _this.props = props;
        _this._tag = 'StrictType';
        return _this;
    }
    return StrictType;
}(Type));
export { StrictType };
/**
 * Drops the codec "kind"
 * @since 1.1.0
 * @deprecated
 */
export function clean(codec) {
    return codec;
}
export function alias(codec) {
    return function () { return codec; };
}
var isNonEmpty = function (as) { return as.length > 0; };
/**
 * @internal
 */
export var emptyTags = {};
function intersect(a, b) {
    var r = [];
    for (var _i = 0, a_1 = a; _i < a_1.length; _i++) {
        var v = a_1[_i];
        if (b.indexOf(v) !== -1) {
            r.push(v);
        }
    }
    return r;
}
function mergeTags(a, b) {
    if (a === emptyTags) {
        return b;
    }
    if (b === emptyTags) {
        return a;
    }
    var r = Object.assign({}, a);
    for (var k in b) {
        if (a.hasOwnProperty(k)) {
            var intersection_1 = intersect(a[k], b[k]);
            if (isNonEmpty(intersection_1)) {
                r[k] = intersection_1;
            }
            else {
                r = emptyTags;
                break;
            }
        }
        else {
            r[k] = b[k];
        }
    }
    return r;
}
function intersectTags(a, b) {
    if (a === emptyTags || b === emptyTags) {
        return emptyTags;
    }
    var r = emptyTags;
    for (var k in a) {
        if (b.hasOwnProperty(k)) {
            var intersection_2 = intersect(a[k], b[k]);
            if (intersection_2.length === 0) {
                if (r === emptyTags) {
                    r = {};
                }
                r[k] = a[k].concat(b[k]);
            }
        }
    }
    return r;
}
function isLiteralC(codec) {
    return codec._tag === 'LiteralType';
}
function isTypeC(codec) {
    return codec._tag === 'InterfaceType';
}
// tslint:disable-next-line: deprecation
function isStrictC(codec) {
    return codec._tag === 'StrictType';
}
function isExactC(codec) {
    return codec._tag === 'ExactType';
}
// tslint:disable-next-line: deprecation
function isRefinementC(codec) {
    return codec._tag === 'RefinementType';
}
function isIntersectionC(codec) {
    return codec._tag === 'IntersectionType';
}
function isUnionC(codec) {
    return codec._tag === 'UnionType';
}
function isRecursiveC(codec) {
    return codec._tag === 'RecursiveType';
}
var lazyCodec = null;
/**
 * @internal
 */
export function getTags(codec) {
    if (codec === lazyCodec) {
        return emptyTags;
    }
    if (isTypeC(codec) || isStrictC(codec)) {
        var index = emptyTags;
        // tslint:disable-next-line: forin
        for (var k in codec.props) {
            var prop = codec.props[k];
            if (isLiteralC(prop)) {
                if (index === emptyTags) {
                    index = {};
                }
                index[k] = [prop.value];
            }
        }
        return index;
    }
    else if (isExactC(codec) || isRefinementC(codec)) {
        return getTags(codec.type);
    }
    else if (isIntersectionC(codec)) {
        return codec.types.reduce(function (tags, codec) { return mergeTags(tags, getTags(codec)); }, emptyTags);
    }
    else if (isUnionC(codec)) {
        return codec.types.slice(1).reduce(function (tags, codec) { return intersectTags(tags, getTags(codec)); }, getTags(codec.types[0]));
    }
    else if (isRecursiveC(codec)) {
        lazyCodec = codec;
        var tags = getTags(codec.type);
        lazyCodec = null;
        return tags;
    }
    return emptyTags;
}
/**
 * @internal
 */
export function getIndex(codecs) {
    var tags = getTags(codecs[0]);
    var keys = Object.keys(tags);
    var len = codecs.length;
    var _loop_6 = function (k) {
        var all = tags[k].slice();
        var index = [tags[k]];
        for (var i = 1; i < len; i++) {
            var codec = codecs[i];
            var ctags = getTags(codec);
            var values = ctags[k];
            // tslint:disable-next-line: strict-type-predicates
            if (values === undefined) {
                return "continue-keys";
            }
            else {
                if (values.some(function (v) { return all.indexOf(v) !== -1; })) {
                    return "continue-keys";
                }
                else {
                    all.push.apply(all, values);
                    index.push(values);
                }
            }
        }
        return { value: [k, index] };
    };
    keys: for (var _i = 0, keys_1 = keys; _i < keys_1.length; _i++) {
        var k = keys_1[_i];
        var state_1 = _loop_6(k);
        if (typeof state_1 === "object")
            return state_1.value;
        switch (state_1) {
            case "continue-keys": continue keys;
        }
    }
    return undefined;
}
