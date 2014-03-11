//
//  MTLJSONAdapterSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

SpecBegin(MTLJSONAdapter)

it(@"should initialize from JSON", ^{
	NSDictionary *values = @{
		@"username": NSNull.null,
		@"count": @"5",
	};

	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:values modelClass:MTLTestModel.class error:&error];
	expect(adapter).notTo.beNil();
	expect(error).to.beNil();

	MTLTestModel *model = (id)adapter.model;
	expect(model).notTo.beNil();
	expect(model.name).to.beNil();
	expect(model.count).to.equal(5);
	
	NSDictionary *JSONDictionary = @{
		@"username": NSNull.null,
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null },
	};

	expect(adapter.JSONDictionary).to.equal(JSONDictionary);
});

it(@"should initialize from a model", ^{
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{
		@"name": @"foobar",
		@"count": @5,
	} error:NULL];

	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithModel:model];
	expect(adapter).notTo.beNil();
	expect(adapter.model).to.beIdenticalTo(model);

	NSDictionary *JSONDictionary = @{
		@"username": @"foobar",
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null },
	};

	expect(adapter.JSONDictionary).to.equal(JSONDictionary);
});

it(@"should initialize nested key paths from JSON", ^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @{ @"name": @"bar" },
		@"count": @"0"
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();

	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.equal(@"bar");

	expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(values);
});

it(@"should return nil and error with an invalid key path from JSON",^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @"bar",
		@"count": @"0"
	};
	
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should support key paths across arrays", ^{
	NSDictionary *values = @{
		@"users": @[
			@{
				@"name": @"foo"
			},
			@{
				@"name": @"bar"
			},
			@{
				@"name": @"baz"
			}
		]
	};

	NSError *error = nil;
	MTLArrayTestModel *model = [MTLJSONAdapter modelOfClass:MTLArrayTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();

	expect(model.names).to.equal((@[ @"foo", @"bar", @"baz" ]));
});

it(@"should initialize without returning any error when using a JSON dictionary which Null.null as value",^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": NSNull.null,
		@"count": @"0"
	};
	
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();
	
	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.beNil();
});

it(@"should return nil and an error with a nil JSON dictionary", ^{
	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:nil modelClass:MTLTestModel.class error:&error];
	expect(adapter).to.beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should return nil and an error with a wrong data type as dictionary", ^{
	NSError *error = nil;
	id wrongDictionary = @"";
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:wrongDictionary modelClass:MTLTestModel.class error:&error];
	expect(adapter).to.beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should ignore unrecognized JSON keys", ^{
	NSDictionary *values = @{
		@"foobar": @"foo",
		@"count": @"2",
		@"_": NSNull.null,
		@"username": @"buzz",
		@"nested": @{ @"name": @"bar", @"stuffToIgnore": @5, @"moreNonsense": NSNull.null },
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();

	expect(model.name).to.equal(@"buzz");
	expect(model.count).to.equal(2);
	expect(model.nestedName).to.equal(@"bar");
});

it(@"should fail to initialize if JSON dictionary validation fails", ^{
	NSDictionary *values = @{
		@"username": @"this is too long a name",
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).to.beNil();
	expect(error.domain).to.equal(MTLTestModelErrorDomain);
	expect(error.code).to.equal(MTLTestModelNameTooLong);
});

it(@"should parse a different model class", ^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @{ @"name": @"bar" },
		@"count": @"0"
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLSubstitutingTestModel.class fromJSONDictionary:values error:&error];
	expect(model).to.beKindOf(MTLTestModel.class);
	expect(error).to.beNil();

	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.equal(@"bar");

	expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(values);
});

it(@"should return an error when no suitable model class is found", ^{
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLSubstitutingTestModel.class fromJSONDictionary:@{} error:&error];
	expect(model).to.beNil();

	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorNoClassFound);
});

SpecEnd
