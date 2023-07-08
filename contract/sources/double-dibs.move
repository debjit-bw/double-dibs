module doubledibs::gambler {

    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use std::string::{Self, String};
    use sui::event::{Self};
    use sui::sui::{SUI};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use std::debug;

    friend doubledibs::gambler_test;

    // #####################################################################
    // #############################  STRUCT  ##############################
    // #####################################################################

    // Seed changes every tx, used to prevent profiting through sandwiching multiple txs into 1 block
    struct Seed has key, store {
        id: UID,
        value: u64,
        incremented_at: u64
    }

    // Config: stores game parameters
    struct Config has key, store {
        id: UID,
        increment_modulo: u64,
        options: u64,
    }

    // Struct containing the map of player -> streak and Sui in reserves
    struct Store has key, store {
        id: UID,
        reserves: Balance<SUI>,
    }

    // NFT minted for winning a streak
    struct DibStreak has key, store {
        id: UID,
        type: String,
        owner: address,
        stake: u64,
        streak: u64,
    }

    // #####################################################################
    // #############################  CONSTS  ##############################
    // #####################################################################

    // Constants
    const ROUND_OFF: u64 = 1_000_000;
    const SUI_PRECISION: u64 = 1_000_000_000;
    // Errors
    const ERR_STAKE_VAL_MISMATCH: u64 = 68;
    const ERR_PLAYER_NOT_OWNER: u64 = 69;
    const NOT_DEPLOYER: u64 = 403;

    // #####################################################################
    // #############################  EVENTS  ##############################
    // #####################################################################

    // Event emitted as a proof of integrity, can be used to verify that the random number was not manipulated
    // Contains the data used to select the particular number/card
    // This event is emitted after the winning card is picked and before the winning choice is matched with the player's choice
    struct Fairplay has copy, drop {
        block_timestamp: u64,
        seed_value: u64,
        options: u64
    }

    // Event emitted when an NFT is minted
    struct Dibs has copy, drop {
        dib_id: ID,
        player: address,
        streak: u64,
        timestamp: u64,
    }

    // #####################################################################
    // ############################  INIT FN  ##############################
    // #####################################################################

    fun init(ctx: &mut TxContext) {
        debug::print<String>(&string::utf8(b"> gambler::init() <"));

        transfer::share_object(Seed { 
            id: object::new(ctx),
            value: 0, 
            incremented_at: 0 
        });

        transfer::share_object(Config { 
            id: object::new(ctx),
            increment_modulo: 101, 
            options: 3,
        });

        transfer::share_object(Store { 
            id: object::new(ctx),
            reserves: balance::zero<SUI>()
        });
    }

    // ######################################################################
    // ############################  ADMIN FN  ##############################
    // ######################################################################

    fun return_to_admin(store: &mut Store,ctx: &mut TxContext) {
        debug::print<String>(&string::utf8(b"> gambler::init() <"));

        assert!(tx_context::sender(ctx) == @deployer, NOT_DEPLOYER);

        let amount = balance::value<SUI>(&store.reserves);
        let reserves = balance::split<SUI>(&mut store.reserves, amount);
        transfer::public_transfer(coin::from_balance(reserves, ctx), @deployer);
    }

    // #####################################################################
    // ###########################  PUBLIC FNS  ############################
    // #####################################################################

    public entry fun play(
        clock: &Clock,
        seed: &mut Seed,
        store: &mut Store,
        config: &Config,
        choice: u64,
        stake: Coin<SUI>,
        card: DibStreak,
        ctx: &mut TxContext
    ) {
        let player = tx_context::sender(ctx);
        let stake_value = coin::value<SUI>(&stake);
        let stake_bal = coin::into_balance<SUI>(stake);

        assert!(card.owner == player, ERR_PLAYER_NOT_OWNER);
        assert!(stake_value == card.stake, ERR_STAKE_VAL_MISMATCH);

        let winning_choice = next_round(clock, config, seed);
        if (winning_choice == choice) {
            // #### WIN ####
            // 1. return staked card
            // 2. mint new card and transfer
            // 3. payout reward

            let new_streak = card.streak + 1;

            transfer::public_transfer(card, player);
            mint_and_transfer(clock, new_streak, ctx);

            // extract stake_value from reserves
            let winnings = balance::split<SUI>(&mut store.reserves, stake_value);
            balance::join(&mut stake_bal, winnings);
        
            let rewards = coin::from_balance(stake_bal, ctx);
            transfer::public_transfer(rewards, player);
        } else {
            // #### LOST ####
            // 1. burn card
            // 2. transfer staked SUI to reserves

            balance::join<SUI>(&mut store.reserves, stake_bal);

            let DibStreak { id, type: _, owner: _, stake: _, streak: _ } = card;
            object::delete(id);
        };
    }

    public entry fun start(
        clock: &Clock,
        seed: &mut Seed,
        store: &mut Store,
        config: &Config,
        choice: u64,
        stake: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let player = tx_context::sender(ctx);
        let stake_value = coin::value<SUI>(&stake);
        let stake_bal = coin::into_balance<SUI>(stake);

        assert!(stake_value == SUI_PRECISION, ERR_STAKE_VAL_MISMATCH);

        let winning_choice = next_round(clock, config, seed);
        if (winning_choice == choice) {
            // #### WIN ####
            // 1. mint new card and transfer
            // 2. payout reward

            mint_and_transfer(clock, 1, ctx);

            // extract stake_value from reserves
            let winnings = balance::split<SUI>(&mut store.reserves, stake_value);
            balance::join(&mut stake_bal, winnings);
        
            let rewards = coin::from_balance(stake_bal, ctx);
            transfer::public_transfer(rewards, player);
        } else {
            // #### LOST ####
            // 1. transfer staked SUI to reserves

            balance::join<SUI>(&mut store.reserves, stake_bal);
        };
    }

    public entry fun overlord_mode(
        store: &mut Store,
        card: DibStreak,
        ctx: &mut TxContext
    ) {
        // this mode allows the player to withdraw half of the treasury (till 5k SUI) and burn the card
        let player = tx_context::sender(ctx);
        assert!(card.owner == player, ERR_PLAYER_NOT_OWNER);

        let reward_val = balance::value<SUI>(&store.reserves);
        if (reward_val > 5 * SUI_PRECISION) reward_val = 5 * SUI_PRECISION;
        let reward = balance::split<SUI>(&mut store.reserves, reward_val);
        
        let jackpot = coin::from_balance(reward, ctx);
        transfer::public_transfer(jackpot, player);

        let DibStreak { id, type: _, owner: _, stake: _, streak: _ } = card;
        object::delete(id);
    }

    // #####################################################################
    // ##########################  INTERNAL FNS  ###########################
    // #####################################################################

    fun mint_and_transfer(clock: &Clock, streak: u64, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let name: String;
        if (streak < 1) {
            return
        } else if (streak == 1) {
            name = string::utf8(b"Genesis White");
        } else if (streak == 2) {
            name = string::utf8(b"Enigma Violet");
        } else if (streak == 3) {
            name = string::utf8(b"Ocean Blue");
        } else if (streak == 4) {
            name = string::utf8(b"Poison Greem");
        } else if (streak == 5) {
            name = string::utf8(b"Dragon Yellow");
        } else if (streak == 6) {
            name = string::utf8(b"Blood Red");
        } else if (streak == 7) {
            name = string::utf8(b"Moon Silver");
        } else if (streak == 8) {
            name = string::utf8(b"Fire Gold");
        } else {
            name = string::utf8(b"Nebula Black");
        };

        let dib = DibStreak {
            id: object::new(ctx),
            type: name,
            owner: sender,
            stake: stake_val(streak),
            streak: streak,
        };

        event::emit( Dibs {
            dib_id: object::id(&dib),
            player: sender,
            streak: streak,
            timestamp: clock::timestamp_ms(clock)
        });

        transfer::public_transfer(dib, sender);

    }

    // #####################################################################
    // ############################  MATH FNS  #############################
    // #####################################################################

    public(friend) fun next_round(clock: &Clock, config: &Config, seed: &mut Seed): u64 {
        update_seed(clock, seed);
        let choice = make_choice(clock::timestamp_ms(clock) + seed.value, config.options);

        event::emit(Fairplay {
            seed_value: seed.value,
            options: config.options,
            block_timestamp: clock::timestamp_ms(clock),
        });

        return choice
    }

    fun make_choice(seed: u64, n: u64): u64 {
        return seed % n
    }

    fun update_seed(clock: &Clock, seed: &mut Seed) {
        seed.value = (seed.value + 1) % ROUND_OFF;
        seed.incremented_at = clock::timestamp_ms(clock);
    }

    public(friend) fun stake_val(streak: u64): u64 {
        if (streak == 0) return 1;
        let i = streak - 1;
        let val = 1;
        while (i > 0) {
            val = val * 2;
            i = i - 1;
        };
        if (val == 1) 1 else val + 1
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}

#[test_only]
module doubledibs::gambler_test {
    use std::debug;
    use std::string::{Self, String};
    use sui::clock::{Self, Clock};
    use sui::test_scenario::{Self, Scenario};
    use doubledibs::gambler::{Self, Config, Seed, next_round, stake_val};

    fun initialize(scenario: &mut Scenario) {
        debug::print<String>(&string::utf8(b"> gambler_test::initialize() <"));

        test_scenario::next_tx(scenario, @test_admin);
        {
            clock::share_for_testing(clock::create_for_testing(test_scenario::ctx(scenario)));
        };

        test_scenario::next_tx(scenario, @test_admin);
        {
            let ctx = test_scenario::ctx(scenario);
            gambler::init_for_testing(ctx);
        };
    }

    #[test]
    fun random_number_test() {
        let scenario = test_scenario::begin(@test_admin);
        initialize(&mut scenario);

        test_scenario::next_tx(&mut scenario, @test_admin); {
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let config = test_scenario::take_shared<Config>(&scenario);
            let seed = test_scenario::take_shared<Seed>(&scenario);
            
            clock::increment_for_testing(&mut clock, 95);
            
            let i = 0;
            while (i < 10) {
                let winning_choice =next_round(&clock, &config, &mut seed);
                debug::print<String>(&string::utf8(b"next_round: "));
                debug::print<u64>(&winning_choice);
                i = i + 1;
            };

            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
            test_scenario::return_shared(seed);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun stake_val_test() {
        let scenario = test_scenario::begin(@test_admin);
        initialize(&mut scenario);

        test_scenario::next_tx(&mut scenario, @test_admin); {
            debug::print<String>(&string::utf8(b"> stake_val_test <"));
            let i = 0;
            while (i < 10) {
                let val = stake_val(i);
                debug::print<String>(&string::utf8(b"streak, val: "));
                debug::print<u64>(&i);
                debug::print<u64>(&val);
                debug::print<String>(&string::utf8(b"---------------"));
                i = i + 1;
            };
        };

        test_scenario::end(scenario);
    }
}