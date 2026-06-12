use asr::{
    future::next_tick,
    time::Duration,
    timer::{self, TimerState},
    Process, Address,
};

asr::async_main!(stable);

struct Watchers {
    game_time: u64,
    current_map: u64,
    player_health: u64,
    health_offset: u64,
    is_level_done: u64,
}

impl Watchers {
    fn new() -> Self {
        Self {
            game_time: 0x1D7EB0,
            current_map: 0x1D7EA8,
            player_health: 0x1D9A48,
            health_offset: 0x1A0,
            is_level_done: 0x1D5348,
        }
    }
}

async fn main() {
    let pointers = Watchers::new();
    
    let mut prev_game_time: u32;
    let mut frame_counter: u32;
    let mut prev_map = String::new();
    let mut prev_is_level_done;

    let mut accumulated_ticks: u64; 
    let mut current_level_ticks: u32;

    loop {        
        let process = match Process::attach("Wrack_steam.exe") {
            Some(p) => p,
            None => {
                next_tick().await;
                continue;
            }
        };

        let base_address = match process.get_module_address("Wrack_steam.exe") {
            Ok(addr) => addr,
            Err(_) => {
                next_tick().await;
                continue;
            }
        };

        prev_game_time = 0;
        frame_counter = 0;
        prev_map.clear();
        prev_is_level_done = false;
        accumulated_ticks = 0;
        current_level_ticks = 0;

        let mut has_accumulated_this_transition = false;

        while process.is_open() {
            next_tick().await;

            let mut is_loading = false;

            if let Ok(heap_string_pointer) = process.read::<u64>(base_address + pointers.current_map) {
                let target_string_address = Address::new(heap_string_pointer);
                
                if let Ok(current_map_bytes) = process.read::<[u8; 50]>(target_string_address) {
                    if let Some(null_pos) = current_map_bytes.iter().position(|&c| c == 0) {
                        if let Ok(map_name) = std::str::from_utf8(&current_map_bytes[..null_pos]) {
                            let map_name = map_name.to_lowercase();

                            if prev_game_time == 0 && map_name == "e1l1.map" {
                                accumulated_ticks = 0;
                                timer::set_game_time(Duration::milliseconds(0));
                            }

                            if map_name != prev_map && !prev_map.is_empty() {
                                
                                if !has_accumulated_this_transition {
                                    accumulated_ticks += current_level_ticks as u64;
                                    has_accumulated_this_transition = true;
                                }
                                
                                if timer::state() == TimerState::Running {
                                    timer::split();
                                }
                            }

                            prev_map = map_name;
                        }
                    }
                }
            }

            if let Ok(game_time) = process.read::<u32>(base_address + pointers.game_time) {
                current_level_ticks = game_time;

                if game_time == 0 {
                    has_accumulated_this_transition = false;
                    is_loading = true; 
                }

                if game_time == prev_game_time {
                    is_loading = true;
                }

                if is_loading {
                    timer::pause_game_time();
                } else {
                    timer::resume_game_time();
                    
                    let total_ticks = accumulated_ticks + (current_level_ticks as u64);
                    let total_milliseconds = (total_ticks * 1000) / 60;
                    timer::set_game_time(Duration::milliseconds(total_milliseconds as i64));
                }
                
                if game_time > 0 && prev_game_time == 0 && frame_counter != 0 {
                    if timer::state() == TimerState::NotRunning {
                        timer::start();
                    }
                }
                
                prev_game_time = game_time;
            }

            frame_counter = frame_counter.wrapping_add(1);
        }
    }
}