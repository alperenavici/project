import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Int "mo:base/Int";  // Int modülünü ekledik
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Option "mo:base/Option";
import Result "mo:base/Result";

actor class AnimalProtection() {
    // Veri tipleri
    public type Animal = {
        id: Text;
        name: Text;
        species: Text;
        location: Text;
        healthStatus: Text;
        lastFed: Time.Time;
        needsHelp: Bool;
        imageUrl: ?Text;
    };

    public type Donation = {
        id: Text;
        donor: Principal;
        amount: Nat;
        timestamp: Time.Time;
        message: ?Text;
    };

    public type HelpRequest = {
        id: Text;
        animalId: Text;
        requestType: Text;
        description: Text;
        status: Text;
        requester: Principal;
        timestamp: Time.Time;
    };

    private let animals = HashMap.HashMap<Text, Animal>(0, Text.equal, Text.hash);
    private let donations = HashMap.HashMap<Text, Donation>(0, Text.equal, Text.hash);
    private let helpRequests = HashMap.HashMap<Text, HelpRequest>(0, Text.equal, Text.hash);
    private var totalDonations: Nat = 0;

    // Hayvan yönetimi
    public shared(msg) func addAnimal(
        name: Text,
        species: Text,
        location: Text,
        healthStatus: Text,
        imageUrl: ?Text
    ): async Result.Result<Text, Text> {
        let id = generateId("ANM");
        let animal: Animal = {
            id;
            name;
            species;
            location;
            healthStatus;
            lastFed = Time.now();
            needsHelp = false;
            imageUrl;
        };
        animals.put(id, animal);
        #ok(id)
    };

    public shared(msg) func updateAnimal(
        id: Text,
        name: ?Text,
        healthStatus: ?Text,
        needsHelp: ?Bool,
        imageUrl: ?Text
    ): async Result.Result<(), Text> {
        switch (animals.get(id)) {
            case (null) { #err("Hayvan bulunamadı") };
            case (?animal) {
                let updatedAnimal: Animal = {
                    id = animal.id;
                    name = Option.get(name, animal.name);
                    species = animal.species;
                    location = animal.location;
                    healthStatus = Option.get(healthStatus, animal.healthStatus);
                    lastFed = Time.now();
                    needsHelp = Option.get(needsHelp, animal.needsHelp);
                    imageUrl = imageUrl;
                };
                animals.put(id, updatedAnimal);
                #ok(())
            };
        }
    };

    // Bağış yönetimi
    public shared(msg) func makeDonation(amount: Nat, message: ?Text): async Result.Result<Text, Text> {
        let id = generateId("DON");
        let donation: Donation = {
            id;
            donor = msg.caller;
            amount;
            timestamp = Time.now();
            message;
        };
        donations.put(id, donation);
        totalDonations += amount;
        #ok(id)
    };

    // Yardım talepleri
    public shared(msg) func createHelpRequest(
        animalId: Text,
        requestType: Text,
        description: Text
    ): async Result.Result<Text, Text> {
        switch (animals.get(animalId)) {
            case (null) { #err("Hayvan bulunamadı") };
            case (?animal) {
                let id = generateId("REQ");
                let request: HelpRequest = {
                    id;
                    animalId;
                    requestType;
                    description;
                    status = "OPEN";
                    requester = msg.caller;
                    timestamp = Time.now();
                };
                helpRequests.put(id, request);
                #ok(id)
            };
        }
    };

    // Sorgulama fonksiyonları
    public query func getAnimal(id: Text): async ?Animal {
        animals.get(id)
    };

    public query func getAllAnimals(): async [Animal] {
        Iter.toArray(animals.vals())
    };

    public query func getAnimalsNeedingHelp(): async [Animal] {
        Iter.toArray(
            Iter.filter(animals.vals(), func (animal: Animal): Bool {
                animal.needsHelp
            })
        )
    };

    public query func getDonations(): async [Donation] {
        Iter.toArray(donations.vals())
    };

    public query func getHelpRequests(status: ?Text): async [HelpRequest] {
        switch(status) {
            case (null) { Iter.toArray(helpRequests.vals()) };
            case (?s) {
                Iter.toArray(
                    Iter.filter(helpRequests.vals(), func (req: HelpRequest): Bool {
                        req.status == s
                    })
                )
            };
        }
    };

    public query func getTotalDonations(): async Nat {
        totalDonations
    };

    // Yardımcı fonksiyonlar
    private func generateId(prefix: Text): Text {
        let timestamp = Int.abs(Time.now()); // Time.now()'u pozitif Int'e çeviriyoruz
        prefix # "-" # Nat.toText(timestamp) # "-" # Nat.toText(totalDonations)
    };
}