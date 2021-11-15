class BIO_JsonElementOrError {
}

class BIO_JsonElement : BIO_JsonElementOrError abstract {
	abstract string serialize();
}

class BIO_JsonNumber : BIO_JsonElement abstract {
	abstract BIO_JsonNumber negate();
}

class BIO_JsonInt : BIO_JsonNumber {
	int i;
	static BIO_JsonInt make(int i=0){
		BIO_JsonInt ii=new("BIO_JsonInt");
		ii.i=i;
		return ii;
	}
	override BIO_JsonNumber negate(){
		i=-i;
		return self;
	}
	override string serialize(){
		return ""..i;
	}
}

class BIO_JsonDouble : BIO_JsonNumber {
	double d;
	static BIO_JsonDouble make(double d=0){
		BIO_JsonDouble dd=new("BIO_JsonDouble");
		dd.d=d;
		return dd;
	}
	override BIO_JsonNumber negate(){
		d=-d;
		return self;
	}
	override string serialize(){
		return ""..d;
	}
}

class BIO_JsonBool : BIO_JsonElement {
	bool b;
	static BIO_JsonBool make(bool b=false){
		BIO_JsonBool bb=new("BIO_JsonBool");
		bb.b=b;
		return bb;
	}
	override string serialize(){
		return b?"true":"false";
	}
}

class BIO_JsonString : BIO_JsonElement {
	string s;
	static BIO_JsonString make(string s=""){
		BIO_JsonString ss=new("BIO_JsonString");
		ss.s=s;
		return ss;
	}
	override string serialize(){
		return BIO_JSON.serialize_string(s);
	}
}

class BIO_JsonNull : BIO_JsonElement {
	static BIO_JsonNull make(){
		return new("BIO_JsonNull");
	}
	override string serialize(){
		return "null";
	}
}

class BIO_JsonError : BIO_JsonElementOrError {
	String what;
	static BIO_JsonError make(string s){
		BIO_JsonError e=new("BIO_JsonError");
		e.what=s;
		return e;
	}
}