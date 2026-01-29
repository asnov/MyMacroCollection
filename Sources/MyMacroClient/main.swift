import MyMacro

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")


let squaredNumber = #computeSquare(number: 3)
print("The square of 3 is \(squaredNumber)")


#declareStructWithValue("Cancodeswift")
assert(DecloMacroStruct.value == "Cancodeswift")


@WebsiteGiver
enum Brands {
    case meta
    case instagram
    case twitter
}

//ForEach(Brands.self) { brand in
//    print("Website for \(brand) is \(brand.website).")
//}
print("Website for \(Brands.meta) is \(Brands.meta.website).")


struct StoringGuyStruct {
    var dict: [AnyHashable: Any] = [:]
    
    @StoringGuy var surnameProp: String
}

var storeGuyExample = StoringGuyStruct()

storeGuyExample.surnameProp = "Kowalski"
print("structExample.surnameProp:", storeGuyExample.surnameProp)

storeGuyExample.surnameProp = "Nowak"
print("structExample.surnameProp:", storeGuyExample.surnameProp)

storeGuyExample.dict["surnameProp"] = "SomeNewValue"
print("structExample.surnameProp:", storeGuyExample.dict["surnameProp"]!)


@StoringGuyAttributes struct OtherStoringGuyStruct {
    var dict: [AnyHashable: Any] = [:]
    var surnameProp: String
    var nameProp: String
}
var otherStoreGuyExample = OtherStoringGuyStruct()
otherStoreGuyExample.nameProp = "Jan"
otherStoreGuyExample.surnameProp = "Smith"
print("otherStoreGuyExample:", otherStoreGuyExample.nameProp, otherStoreGuyExample.surnameProp)


@AddAsync
func fetchData(_ url: String, completionBlock: @escaping (Result<Int, Error>) -> Void) {
    completionBlock(.success(200))
    print("from inside, url=\(url)")
}

let httpCode = try await fetchData("http://localhost")
print("httpCode=\(httpCode)")
