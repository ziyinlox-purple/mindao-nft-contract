module mindao::MinDao {
    use std::error;
    use std::option;
    use std::string::{Self, String};
    use std::signer;

    use aptos_framework::object::{Self, Object};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use aptos_token_objects::property_map;
    use aptos_framework::event;
    use aptos_std::string_utils::{to_string};
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::timestamp;

    /// The token does not exist
    const ETOKEN_DOES_NOT_EXIST: u64 = 1;
    /// The provided signer is not the creator
    const ENOT_CREATOR: u64 = 2;
    /// Attempted to mutate an immutable field
    const EFIELD_NOT_MUTABLE: u64 = 3;
    /// Attempted to burn a non-burnable token
    const ETOKEN_NOT_BURNABLE: u64 = 4;
    /// Attempted to mutate a property map that is not mutable
    const EPROPERTIES_NOT_MUTABLE: u64 = 5;
    // The collection does not exist
    const ECOLLECTION_DOES_NOT_EXIST: u64 = 6;

    /// The mindao token collection name
    const COLLECTION_NAME: vector<u8> = b"MinDAO";
    /// The mindao token collection description
    const COLLECTION_DESCRIPTION: vector<u8> = b"DAO system based on personality type Having fun and opportunities by your unique mind";
    /// The mindao token collection URI
    const COLLECTION_URI: vector<u8> = b"https://harlequin-defiant-pheasant-804.mypinata.cloud/ipfs/bafybeic34egpwh26orz7zgybm5sobhkbpooyq3crfrrqx6w5jxyk72q6jq";

    /// MBTI Personality Types enum structure
    struct MbtiType has copy, drop, store {
        /// The MBTI type in bytes format
        value: vector<u8>
    }

    /// MBTI Type constants
    /// SP Realists
    const ESTP: vector<u8> = b"ESTP";
    const ESFP: vector<u8> = b"ESFP";
    const ISTP: vector<u8> = b"ISTP";
    const ISFP: vector<u8> = b"ISFP";

    /// SJ Guardians
    const ESTJ: vector<u8> = b"ESTJ";
    const ESFJ: vector<u8> = b"ESFJ";
    const ISTJ: vector<u8> = b"ISTJ";
    const ISFJ: vector<u8> = b"ISFJ";

    /// NT Rationals
    const ENTJ: vector<u8> = b"ENTJ";
    const ENTP: vector<u8> = b"ENTP";
    const INTJ: vector<u8> = b"INTJ";
    const INTP: vector<u8> = b"INTP";

    /// NF Idealists
    const ENFJ: vector<u8> = b"ENFJ";
    const ENFP: vector<u8> = b"ENFP";
    const INFJ: vector<u8> = b"INFJ";
    const INFP: vector<u8> = b"INFP";

    /// Invalid MBTI type error
    const EINVALID_MBTI_TYPE: u64 = 7;

    /// Create a new MbtiType from a vector<u8>
    public fun new_mbti_type(value: vector<u8>): MbtiType {
        // Validate that the type is one of the defined MBTI types
        assert!(is_valid_mbti_type(&value), error::invalid_argument(EINVALID_MBTI_TYPE));
        MbtiType { value }
    }

    /// Get the value of an MbtiType
    public fun get_value(mbti_type: &MbtiType): vector<u8> {
        mbti_type.value
    }

    /// Check if a vector<u8> is a valid MBTI type
    public fun is_valid_mbti_type(value: &vector<u8>): bool {
        *value == ESTP || *value == ESFP || *value == ISTP || *value == ISFP ||
        *value == ESTJ || *value == ESFJ || *value == ISTJ || *value == ISFJ ||
        *value == ENTJ || *value == ENTP || *value == INTJ || *value == INTP ||
        *value == ENFJ || *value == ENFP || *value == INFJ || *value == INFP
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// The minDao token
    struct MinDaoToken has key {
        /// Used to mutate the token uri
        mutator_ref: token::MutatorRef,
        /// Used to burn.
        burn_ref: token::BurnRef,
        /// Used to mutate properties
        property_mutator_ref: property_map::MutatorRef,
        /// the base URI of the token
        base_uri: String,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// The minDao level
    struct MinDaoType has key {
        minDao_type: vector<u8>,
    }

    #[event]
    /// The minDao level update event
    struct MbtiChange has drop, store {
        token: Object<MinDaoToken>,
        old_level: vector<u8>,
        new_level: vector<u8>,
    }

    struct Cap has key {
        cap: SignerCapability,
    }

    /// Initializes the module, creating the minDao collection. The creator of the module is the creator of the
    /// minDao collection. As this init function is called only once when the module is published, there will
    /// be only one minDao collection.
    fun init_module(contract: &signer) {
        let (signer, cap) = account::create_resource_account(contract, b"MinDao");
        create_minDao_collection(&signer);
        move_to(
            contract,
            Cap {
                cap
            }
        )
    }

    inline fun get_creator_signer():signer{
        account::create_signer_with_capability(&Cap[@mindao].cap)
    }

    #[view]
    /// Returns the minDao level of the token
    public fun minDao_type(token: Object<MinDaoToken>): vector<u8> acquires MinDaoType {
        let minDao_level = borrow_global<MinDaoType>(object::object_address(&token));
        minDao_level.minDao_type
    }

    /// Returns the minDao level of the token as an MbtiType
    public fun get_mbti_type(token: Object<MinDaoToken>): MbtiType acquires MinDaoType {
        let mbti_value = minDao_type(token);
        MbtiType { value: mbti_value }
    }

    #[view]
    /// Returns the minDao level of the token of the address
    public fun minDao_type_from_address(addr: address): vector<u8> acquires MinDaoType {
        let token = object::address_to_object<MinDaoToken>(addr);
        minDao_type(token)
    }

    /// Creates the minDao collection. This function creates a collection with unlimited supply using
    /// the module constants for description, name, and URI, defined above. The collection will not have
    /// any royalty configuration because the tokens in this collection will not be transferred or sold.
    fun create_minDao_collection(creator: &signer) {
        // Constructs the strings from the bytes.
        let description = string::utf8(COLLECTION_DESCRIPTION);
        let name = string::utf8(COLLECTION_NAME);
        let uri = string::utf8(COLLECTION_URI);

        // Creates the collection with unlimited supply and without establishing any royalty configuration.
        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri,
        );
    }

    /// Mints an minDao token. This function mints a new minDao token and transfers it to the
    /// `soul_bound_to` address. The token is minted with level 0 and rank Bronze.
    public entry fun mint_minDao_token(
        creator: &signer,
        description: String,
        name: String,
        base_uri: String,
        soul_bound_to: address,
        mbti_type: vector<u8>,
    ) {
        mint_minDao_token_impl(creator, description, name, base_uri, soul_bound_to, false, mbti_type);
    }

    /// Mints an minDao token. This function mints a new minDao token and transfers it to the
    public entry fun mint_numbered_minDao_token(
        creator: &signer,
        description: String,
        name: String,
        base_uri: String,
        soul_bound_to: address,
        mbti_type: vector<u8>,
    ) {
        mint_minDao_token_impl(creator, description, name, base_uri, soul_bound_to, true, mbti_type);
    }

    /// Function used for benchmarking.
    public entry fun mint_minDao_token_by_user(
        user: &signer,
        mbti_type: String,
    ) acquires Cap {
        let user_addr = signer::address_of(user);
        let mbti_type_bytes = *mbti_type.bytes();
        assert!(is_valid_mbti_type(&mbti_type_bytes), error::invalid_argument(EINVALID_MBTI_TYPE));
        let uri = string::utf8(b"https://harlequin-defiant-pheasant-804.mypinata.cloud/ipfs/bafybeihc55f3m5alh5wydxjlj4mp73yq2uadapomk2f7unvygh4y6iofji/");
        // mint_minDao_token(&get_creator_signer(), mbti_type, to_string<address>(&user_addr), uri, user_addr, mbti_type_bytes);
        mint_minDao_token(&get_creator_signer(), mbti_type, mbti_type, uri, user_addr, mbti_type_bytes);
    }

    /// Function used for benchmarking.
    /// Uses multisig to mint to user, with creator permissions.
    public entry fun mint_numbered_minDao_token_by_user(
        user: &signer,
        description: String,
        name: String,
        uri: String,
        mbti_type: vector<u8>,
    ) acquires Cap {
        mint_numbered_minDao_token(&get_creator_signer(), description, name, uri, signer::address_of(user), mbti_type);
    }

    /// Mints an minDao token. This function mints a new minDao token and transfers it to the
    /// `soul_bound_to` address. The token is minted with level 0 and rank Bronze.
    fun mint_minDao_token_impl(
        creator: &signer,
        description: String,
        name: String,
        base_uri: String,
        soul_bound_to: address,
        numbered: bool,
        mbti_type: vector<u8>,
    ) {
        // The collection name is used to locate the collection object and to create a new token object.
        let collection = string::utf8(COLLECTION_NAME);
        // Creates the minDao token, and get the constructor ref of the token. The constructor ref
        // is used to generate the refs of the token.
        let uri = base_uri;
        uri.append(string::utf8(mbti_type));
        uri.append_utf8(b".png");
        let constructor_ref = if (numbered) {
            token::create_numbered_token(
                creator,
                collection,
                description,
                name,
                string::utf8(b""),
                option::none(),
                uri,
            )
        } else {
            token::create_named_token(
                creator,
                collection,
                description,
                name,
                option::none(),
                uri,
            )
        };

        // Generates the object signer and the refs. The object signer is used to publish a resource
        // (e.g., MinDaoLevel) under the token object address. The refs are used to manage the token.
        let object_signer = object::generate_signer(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        // Transfers the token to the `soul_bound_to` address
        let linear_transfer_ref = object::generate_linear_transfer_ref(&transfer_ref);
        object::transfer_with_ref(linear_transfer_ref, soul_bound_to);

        // Disables ungated transfer, thus making the token soulbound and non-transferable
        object::disable_ungated_transfer(&transfer_ref);

        // Initializes the minDao level as 0
        move_to(&object_signer, MinDaoType { minDao_type: mbti_type });

        // Initialize the property map and the minDao rank as Bronze
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);

        // In tests this might fail but we'll catch it in production
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"LastUpdateTime"),
            timestamp::now_seconds()
        );

        // Publishes the MinDaoToken resource with the refs.
        let minDao_token = MinDaoToken {
            mutator_ref,
            burn_ref,
            property_mutator_ref,
            base_uri
        };
        move_to(&object_signer, minDao_token);
    }

    /// Burns an minDao token. This function burns the minDao token and destroys the
    /// MinDaoToken resource, MinDaoLevel resource, the event handle, and the property map.
    public entry fun burn(creator: &signer, token: Object<MinDaoToken>) acquires MinDaoToken, MinDaoType {
        authorize_creator(creator, &token);
        let minDao_token = move_from<MinDaoToken>(object::object_address(&token));
        let MinDaoToken {
            mutator_ref: _,
            burn_ref,
            property_mutator_ref,
            base_uri: _
        } = minDao_token;

        let MinDaoType {
            minDao_type: _
        } = move_from<MinDaoType>(object::object_address(&token));

        property_map::burn(property_mutator_ref);
        token::burn(burn_ref);
    }

    /// Function used for benchmarking.
    /// Uses multisig to mint to user, with creator permissions.
    /// Uses users address as unique name of the soulbound token.
    /// Burns token that was minted by mint_minDao_token_by_user
    public entry fun burn_named_by_user(user: &signer, creator: &signer) acquires MinDaoToken, MinDaoType {
        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection_name,
            &to_string<address>(&signer::address_of(user)),
        );
        let token = object::address_to_object<MinDaoToken>(token_address);
        burn(creator, token);
    }

    /// Sets the minDao level of the token. Only the creator of the token can set the level. When the level
    /// is updated, the `LevelUpdate` is emitted. The minDao rank is updated based on the new level.
    public entry fun set_minDao_type(
        creator: &signer,
        token: Object<MinDaoToken>,
        new_minDao_type: vector<u8>
    ) acquires MinDaoType, MinDaoToken {
        // Validate that the new MBTI type is valid
        assert!(is_valid_mbti_type(&new_minDao_type), error::invalid_argument(EINVALID_MBTI_TYPE));

        // Asserts that `creator` is the creator of the token.
        authorize_creator(creator, &token);

        let token_address = object::object_address(&token);
        let minDao_type = borrow_global_mut<MinDaoType>(token_address);
        // Emits the `LevelUpdate`.
        event::emit(
            MbtiChange {
                token,
                old_level: minDao_type.minDao_type,
                new_level: new_minDao_type,
            }
        );
        // Updates the minDao level.
        minDao_type.minDao_type = new_minDao_type;

        let token_address = object::object_address(&token);
        let ambassador_token = borrow_global<MinDaoToken>(token_address);
        // Gets `property_mutator_ref` to update the rank in the property map.
        let property_mutator_ref = &ambassador_token.property_mutator_ref;
        // Updates the rank in the property map.
        // Update the timestamp property if possible
        // We directly use timestamp::now_seconds() which works in both test and production
        property_map::update_typed(property_mutator_ref, &string::utf8(b"LastUpdateTime"),
            timestamp::now_seconds());
        // Updates the token URI based on the new rank.
        let uri = ambassador_token.base_uri;
        uri.append(string::utf8(new_minDao_type));
        token::set_uri(&ambassador_token.mutator_ref, uri);
    }

    /// Authorizes the creator of the token. Asserts that the token exists and the creator of the token
    /// is `creator`.
    inline fun authorize_creator<T: key>(creator: &signer, token: &Object<T>) {
        let token_address = object::object_address(token);
        assert!(
            exists<T>(token_address),
            error::not_found(ETOKEN_DOES_NOT_EXIST),
        );
        assert!(
            token::creator(*token) == signer::address_of(creator),
            error::permission_denied(ENOT_CREATOR),
        );
    }

    #[test(creator = @0x123, user1 = @0x456, framework = @aptos_framework)]
    fun test_mint_burn(creator: &signer, user1: &signer, framework: &signer) acquires MinDaoToken, MinDaoType {
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(framework);
        // ------------------------------------------
        // Creator creates the MinDao Collection.
        // ------------------------------------------
        create_minDao_collection(creator);

        // -------------------------------------------
        // Creator mints a MinDao token for User1.
        // -------------------------------------------
        let token_name = string::utf8(b"MinDao Token #1");
        let token_description = string::utf8(b"MinDao Token #1 Description");
        let token_uri = string::utf8(b"MinDao Token #1 URI/");
        let user1_addr = signer::address_of(user1);
        // Creates the MinDao token for User1.
        mint_minDao_token(
            creator,
            token_description,
            token_name,
            token_uri,
            user1_addr,
            TYPE_ESTP
        );
        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection_name,
            &token_name
        );
        let token = object::address_to_object<MinDaoToken>(token_address);
        // Asserts that the owner of the token is User1.
        assert!(object::owner(token) == user1_addr, 1);

        // -----------------------
        // Creator sets the level.
        // -----------------------
        // Asserts that the initial MBTI type of the token is ESTP.
        assert!(minDao_type(token) == TYPE_ESTP, 2);
        // Asserts that the initial token URI includes the base URI and MBTI type (ESTP).
        assert!(token::uri(token) == string::utf8(b"MinDao Token #1 URI/ESTP"), 3);
        // `creator` sets the MBTI type to ISFP.
        set_minDao_type(creator, token, TYPE_ISFP);
        // Asserts that the MBTI type is updated to ISFP.
        assert!(minDao_type(token) == TYPE_ISFP, 4);
        // Asserts that the URI is updated with the new type (ISFP).
        assert!(token::uri(token) == string::utf8(b"MinDao Token #1 URI/ISFP"), 5);

        // ------------------------
        // Creator burns the token.
        // ------------------------
        let token_addr = object::object_address(&token);
        // Asserts that the token exists before burning.
        assert!(exists<MinDaoToken>(token_addr), 6);
        // Burns the token.
        burn(creator, token);
        // Asserts that the token does not exist after burning.
        assert!(!exists<MinDaoToken>(token_addr), 7);
    }

    #[test(creator = @0x123, user1 = @0x456, user2 = @0x789, framework = @aptos_framework)]
    fun test_multiple_mbti_types(
        creator: &signer,
        user1: &signer,
        user2: &signer,
        framework: &signer
    ) acquires MinDaoToken, MinDaoType {
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(framework);
        // ------------------------------------------
        // Creator creates the MinDao Collection.
        // ------------------------------------------
        create_minDao_collection(creator);

        // -------------------------------------------
        // Creator mints tokens with different MBTI types.
        // -------------------------------------------
        // Mint token with SP type (ESTP)
        let token1_name = string::utf8(b"ESTP Token");
        let token1_description = string::utf8(b"SP Type Token");
        let token1_uri = string::utf8(b"Token URI/");
        let user1_addr = signer::address_of(user1);

        mint_minDao_token(
            creator,
            token1_description,
            token1_name,
            token1_uri,
            user1_addr,
            TYPE_ESTP
        );

        // Mint token with SJ type (ESTJ)
        let token2_name = string::utf8(b"ESTJ Token");
        let token2_description = string::utf8(b"SJ Type Token");
        let token2_uri = string::utf8(b"Token URI/");
        let user2_addr = signer::address_of(user2);

        mint_minDao_token(
            creator,
            token2_description,
            token2_name,
            token2_uri,
            user2_addr,
            TYPE_ESTJ
        );

        // Verify tokens have correct MBTI types
        let collection_name = string::utf8(COLLECTION_NAME);
        let token1_address = token::create_token_address(
            &signer::address_of(creator),
            &collection_name,
            &token1_name
        );
        let token2_address = token::create_token_address(
            &signer::address_of(creator),
            &collection_name,
            &token2_name
        );

        let token1 = object::address_to_object<MinDaoToken>(token1_address);
        let token2 = object::address_to_object<MinDaoToken>(token2_address);

        assert!(minDao_type(token1) == TYPE_ESTP, 1);
        assert!(minDao_type(token2) == TYPE_ESTJ, 2);

        // Change token1 to NT type (INTJ)
        set_minDao_type(creator, token1, TYPE_INTJ);
        assert!(minDao_type(token1) == TYPE_INTJ, 3);

        // Change token2 to NF type (ENFP)
        set_minDao_type(creator, token2, TYPE_ENFP);
        assert!(minDao_type(token2) == TYPE_ENFP, 4);

        // Cleanup - burn tokens
        burn(creator, token1);
        burn(creator, token2);
    }

    #[test(creator = @0x123, user1 = @0x456, non_creator = @0x789, framework = @aptos_framework)]
    #[expected_failure]
    fun test_permission_denied_set_type(creator: &signer, user1: &signer, non_creator: &signer, framework: &signer)
    acquires MinDaoToken, MinDaoType {
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(framework);
        // ------------------------------------------
        // Creator creates the MinDao Collection.
        // ------------------------------------------
        create_minDao_collection(creator);

        // -------------------------------------------
        // Creator mints a MinDao token for User1.
        // -------------------------------------------
        let token_name = string::utf8(b"MinDao Token");
        let token_description = string::utf8(b"Token Description");
        let token_uri = string::utf8(b"Token URI/");
        let user1_addr = signer::address_of(user1);

        mint_minDao_token_impl(
            creator,
            token_description,
            token_name,
            token_uri,
            user1_addr,
            false,
            ENFJ
        );

        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection_name,
            &token_name
        );
        let token = object::address_to_object<MinDaoToken>(token_address);

        // Non-creator attempts to change MBTI type - should fail
        set_minDao_type(non_creator, token, INFP);
    }

    #[test(creator = @0x123, user1 = @0x456, non_creator = @0x789, framework = @aptos_framework)]
    #[expected_failure]
    fun test_permission_denied_burn(creator: &signer, user1: &signer, non_creator: &signer, framework: &signer)
    acquires MinDaoToken, MinDaoType {
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(framework);
        // ------------------------------------------
        // Creator creates the MinDao Collection.
        // ------------------------------------------
        create_minDao_collection(creator);

        // -------------------------------------------
        // Creator mints a MinDao token for User1.
        // -------------------------------------------
        let token_name = string::utf8(b"MinDao Token");
        let token_description = string::utf8(b"Token Description");
        let token_uri = string::utf8(b"Token URI/");
        let user1_addr = signer::address_of(user1);

        mint_minDao_token_impl(
            creator,
            token_description,
            token_name,
            token_uri,
            user1_addr,
            false,
            ENFJ
        );

        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection_name,
            &token_name
        );
        let token = object::address_to_object<MinDaoToken>(token_address);

        // Non-creator attempts to burn token - should fail
        burn(non_creator, token);
    }

    #[test(creator = @0x123, user1 = @0x456, framework = @aptos_framework)]
    fun test_multiple_type_changes(
        creator: &signer,
        user1: &signer,
        framework: &signer
    ) acquires MinDaoToken, MinDaoType {
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(framework);
        // ------------------------------------------
        // Creator creates the MinDao Collection.
        // ------------------------------------------
        create_minDao_collection(creator);

        // Mint a token
        let token_name = string::utf8(b"Token for Type Changes");
        let token_description = string::utf8(b"Test multiple MBTI changes");
        let token_uri = string::utf8(b"Token URI/");
        let user1_addr = signer::address_of(user1);

        mint_minDao_token(
            creator,
            token_description,
            token_name,
            token_uri,
            user1_addr,
            ISTP
        );

        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection_name,
            &token_name
        );
        let token = object::address_to_object<MinDaoToken>(token_address);

        // Initial type verification
        assert!(minDao_type(token) == ISTP, 1);

        // Change MBTI type multiple times
        set_minDao_type(creator, token, ESFJ);
        assert!(minDao_type(token) == ESFJ, 2);

        set_minDao_type(creator, token, ENTJ);
        assert!(minDao_type(token) == ENTJ, 3);

        set_minDao_type(creator, token, INFP);
        assert!(minDao_type(token) == INFP, 4);

        // Change back to original type
        set_minDao_type(creator, token, ISTP);
        assert!(minDao_type(token) == ISTP, 5);

        // Cleanup
        burn(creator, token);
    }

    #[test(creator = @0x123, user1 = @0x456, framework = @aptos_framework)]
    fun test_view_functions(creator: &signer, user1: &signer, framework: &signer) acquires MinDaoToken, MinDaoType {
        // Initialize timestamp for testing
        timestamp::set_time_has_started_for_testing(framework);
        // ------------------------------------------
        // Creator creates the MinDao Collection.
        // ------------------------------------------
        create_minDao_collection(creator);

        // Mint a token
        let token_name = string::utf8(b"View Function Test");
        let token_description = string::utf8(b"Testing view functions");
        let token_uri = string::utf8(b"Token URI/");
        let user1_addr = signer::address_of(user1);

        mint_minDao_token(
            creator,
            token_description,
            token_name,
            token_uri,
            user1_addr,
            INTJ
        );

        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address = token::create_token_address(
            &signer::address_of(creator),
            &collection_name,
            &token_name
        );
        let token = object::address_to_object<MinDaoToken>(token_address);

        // Test view functions
        assert!(minDao_type(token) == INTJ, 1);
        assert!(minDao_type_from_address(token_address) == INTJ, 2);

        // Change type and verify again
        set_minDao_type(creator, token, ENFP);
        assert!(minDao_type(token) == ENFP, 3);
        assert!(minDao_type_from_address(token_address) == ENFP, 4);

        // Cleanup
        burn(creator, token);
    }
}