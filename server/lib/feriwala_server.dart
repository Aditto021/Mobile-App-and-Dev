/// MODULE: FeriWala server library — what bin/server.dart and the tests
/// use to build the API.
library;

export 'src/api.dart' show ShopServer, orderStatuses;
export 'src/catalogue.dart' show Catalogue;
export 'src/rules.dart' show Rules, Quote, quoteFor;
export 'src/store.dart' show Store, User, CartData;
