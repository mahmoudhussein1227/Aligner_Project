# Aligner Project

This repository contains the RTL, UVM testbench, and ModelSim/Questa simulation
files for the Aligner module. The module accepts unaligned Memory Data (MD)
transfers on its RX interface, aligns them according to the APB-programmed
`CTRL.SIZE` and `CTRL.OFFSET` fields, and emits aligned MD transfers on its TX
interface.

The design specification is summarized by the following key rules:

- `ALGN_DATA_WIDTH` defaults to 32 bits and must be a power of two with a
	minimum value of 8.
- The default FIFO depth is 8.
- An MD transfer is legal when
	`((ALGN_DATA_WIDTH / 8) + offset) % size == 0` and
	`size + offset <= (ALGN_DATA_WIDTH / 8)`.
- APB registers are mapped at `CTRL=0x0000`, `STATUS=0x000C`,
	`IRQEN=0x00F0`, and `IRQ=0x00F4`.

## Repository Layout

| Directory | Contents |
| --- | --- |
| [`RTL/`](RTL) | Aligner RTL and its submodules. |
| [`testbench/`](testbench) | UVM environment, agents, model, register model, sequences, tests, and coverage. |
| [`sim/run.do`](sim/run.do) | ModelSim/Questa compilation, elaboration, and simulation script. |
| [`docs/`](docs) | Design documentation and diagrams. |

Generated simulator databases, waveforms, logs, and other files under `sim/`
are intentionally ignored; only `sim/run.do` is versioned.

## UVM Testbench Architecture

The top-level environment is `cfs_algn_env` in
[`testbench/cfs_algn_env.sv`](testbench/cfs_algn_env.sv). It instantiates and
connects these components:

```text
												 APB register access
															 |
											 APB agent + predictor
															 |
												 register model
															 |
RX MD interface            Aligner DUT             TX MD interface
			|                         |                         |
MD master agent  ------------>  |  <----------------  MD slave agent
			|                         |                         |
			+------> reference model +------> scoreboard <-----+
															|
								 IRQ prediction and split coverage
```

The virtual sequencer, [`cfs_algn_virtual_sequencer.sv`](testbench/cfs_algn_virtual_sequencer.sv),
holds handles to the APB sequencer, the MD RX sequencer, the MD TX sequencer,
and the reference model. This lets virtual sequences coordinate configuration,
input traffic, downstream TX responses, and status reads.

### APB Agent

The APB agent is implemented in [`cfs_apb_agent.sv`](testbench/cfs_apb_agent.sv)
and follows the usual UVM active-agent structure:

- `cfs_apb_sequencer` supplies APB sequence items.
- `cfs_apb_driver` drives APB transfers.
- `cfs_apb_monitor` observes completed transfers and publishes monitor items.
- `cfs_apb_coverage` samples direction, response, transfer spacing, transfer
	length, operation transitions, and reset-time access activity.
- `cfs_apb_reg_predictor` converts observed APB transfers into register-model
	predictions.

The APB monitor connects to the predictor and to APB coverage in the agent.
The predictor uses the custom adapter in
[`cfs_algn_apb_adapter.sv`](testbench/cfs_algn_apb_adapter.sv) and the model's
default register map.

### MD Agents: RX Master and TX Slave

The two MD agents are the central stimulus and response interfaces for the
Aligner:

- `cfs_md_agent_master#(32)` represents the DUT RX side. It is the MD **master**
	because it drives `valid`, `data`, `offset`, and `size` into the DUT. In the
	testbench naming this is the RX agent.
- `cfs_md_agent_slave#(32)` represents the DUT TX side. It is the MD **slave**
	because it responds to DUT-generated TX transfers by driving `ready` and
	`err`. In the testbench naming this is the TX agent.

Both specializations reuse the generic implementation in
[`cfs_md_agent.sv`](testbench/cfs_md_agent.sv), which contains the driver,
sequencer, monitor, and MD coverage component. Factory overrides select the
master or slave configuration, driver, and sequencer in
[`cfs_md_agent_master.sv`](testbench/cfs_md_agent_master.sv) and
[`cfs_md_agent_slave.sv`](testbench/cfs_md_agent_slave.sv).

The MD monitor in [`cfs_md_monitor.sv`](testbench/cfs_md_monitor.sv) observes
the valid/ready handshake. It publishes an initial transaction when `valid`
asserts and a completed transaction after `ready`, including:

- payload bytes and offset;
- transaction size;
- handshake length and response (`CFS_MD_OK` or `CFS_MD_ERR`);
- delay from the preceding transaction.

The RX master driver holds `valid` and payload fields until `ready`. The TX
slave driver waits for a DUT TX transfer, applies a programmable response
delay, drives `ready` and `err`, and supports `ready_at_end` behavior. The TX
slave sequencer uses the monitor's pending transaction queue so that TX
responses correspond to actual DUT output transfers.

MD transaction item and sequence definitions are grouped in
[`cfs_md_pkg.sv`](testbench/cfs_md_pkg.sv). The master item constrains payload
size and offset to fit the MD data bus; the normal master sequence additionally
uses the legal alignment constraints.

## Reference Model and Scoreboard

### Reference Model

[`cfs_algn_model.sv`](testbench/cfs_algn_model.sv) is a cycle-aware behavioral
model of the Aligner's data path, FIFO levels, status fields, and interrupts.
It receives completed RX and TX observations through analysis imports.

For RX input, the model:

1. Checks the MD legality equations.
2. Returns an expected RX response immediately for an illegal transfer.
3. Increments `STATUS.CNT_DROP` for illegal transfers, saturating at 255.
4. Pushes legal transfers into a model RX FIFO and tracks `STATUS.RX_LVL`.
5. Builds a byte buffer from RX FIFO items.
6. Splits an item when only part of it is needed to complete the configured
	 aligned transfer.
7. Produces aligned TX items of `CTRL.SIZE` bytes at `CTRL.OFFSET` and tracks
	 `STATUS.TX_LVL`.

The model synchronizes its FIFO operations with DUT activity using the DUT
interface's RX/TX FIFO push and pop indicators. It also models empty/full
events for both FIFOs, the saturated drop counter, sticky `IRQ` bits, and the
enabled IRQ pulse on the model's IRQ analysis port.

The model publishes expected results on separate analysis ports:

- expected RX response;
- expected TX MD item;
- expected IRQ pulse;
- split-specific coverage information.

Reset handling clears model FIFOs and buffers, resets the register model, kills
background processes, and restarts alignment, TX control, and IRQ monitoring.

### Scoreboard

[`cfs_algn_scoreboard.sv`](testbench/cfs_algn_scoreboard.sv) compares model
outputs with DUT observations:

- expected RX responses versus RX agent completions;
- expected TX items versus TX agent completions;
- expected IRQ pulses versus the DUT `irq` signal;
- watchdog timers detect missing responses, TX transfers, or IRQs.

The scoreboard queues expected values so RX, TX, and IRQ checking can proceed
independently. Its queues, watchdog processes, and IRQ monitor are reset at
each reset event.

## UVM Register Model

The register model is defined in [`cfs_algn_reg_block.sv`](testbench/cfs_algn_reg_block.sv)
and the field classes beside it. It creates a little-endian, byte-addressed
32-bit APB map and enables read checking.

| Register | Offset | Access | Main fields |
| --- | ---: | --- | --- |
| `CTRL` | `0x0000` | RW | `SIZE[2:0]`, `OFFSET[9:8]`, `CLR[16]` (WO) |
| `STATUS` | `0x000C` | RO | `CNT_DROP[7:0]`, `RX_LVL[11:8]`, `TX_LVL[19:16]` |
| `IRQEN` | `0x00F0` | RW | RX/TX FIFO empty/full enables and `MAX_DROP` enable |
| `IRQ` | `0x00F4` | W1C fields | RX/TX FIFO empty/full and `MAX_DROP` sticky requests |

`CTRL.SIZE` and `CTRL.OFFSET` include constraints matching the specification.
The callback in [`cfs_clr_cnt_drp_cbs.sv`](testbench/cfs_clr_cnt_drp_cbs.sv)
implements the `CTRL.CLR` side effect by clearing the model's drop counter.
The register block is connected to the APB sequencer through the custom adapter,
and observed bus activity is fed back through the predictor.

## Coverage

Coverage is collected at three levels.

### APB Agent Coverage

[`cfs_apb_coverage.sv`](testbench/cfs_apb_coverage.sv) samples:

- read/write direction and APB response;
- back-to-back, short-delay, and long-delay transfers;
- APB transfer length, including an illegal-bin check for too-short transfers;
- read/write operation transitions;
- whether an access is active during reset handling.

### MD Agent Coverage

[`cfs_md_coverage.sv`](testbench/cfs_md_coverage.sv) samples each observed MD
item's response, payload length, inter-item delay, offset, and payload size.
It crosses size and offset while ignoring combinations that exceed the MD data
bus width. It also samples reset activity through the MD virtual interface.
The same component is reused by both the RX master and TX slave agent
instances.

### Environment-Level Split Coverage

[`cfs_algn_coverage.sv`](testbench/cfs_algn_coverage.sv) samples the
`cfs_algn_coverage_info` objects emitted by the reference model when an RX
item must be split. [`cfs_algn_coverage_info.sv`](testbench/cfs_algn_coverage_info.sv)
records:

- incoming RX item size and offset;
- configured `CTRL.SIZE` and `CTRL.OFFSET`;
- the number of bytes needed to complete the current TX item.

The `cover_split` covergroup crosses all five values and excludes impossible
control configurations. This is the environment-level coverage that targets
the alignment split functionality rather than only individual interface
transactions.

## Virtual Sequences

All Aligner virtual sequences are included by
[`cfs_algn_pkg.sv`](testbench/cfs_algn_pkg.sv) and run through the virtual
sequencer.

| Sequence | Purpose |
| --- | --- |
| `cfs_algn_virtual_sequence` | Coordinates one legal RX transfer with the corresponding number of TX responses. It constrains the RX transfer to the bus legality rules and expects the final TX response to terminate the aligned transfer. |
| `cfs_algn_random_md_tr_v_sequence` | Starts a randomized legal MD RX master sequence. |
| `cfs_algn_illegal_rx_tr_v_sequence` | Overrides the legal RX constraints and generates transfers violating at least one legality equation. |
| `cfs_algn_reg_config_v_sequence` | Finds writable registers in the register map, randomizes them, and performs register-model updates. This is used to configure the control and interrupt-enable registers. |
| `cfs_algn_read_status_regs_v_sequence` | Finds RO registers and reads the status register set through the register model. |
| `cfs_algn_mapped_reg_v_sequence` | Performs randomized reads and writes to mapped registers, with randomized idle gaps. |
| `cfs_algn_unmapped_reg_v_sequence` | Generates APB accesses outside all mapped register byte ranges to verify error handling. |

The lower-level MD sequences are in [`cfs_md_sequence_simple_master.sv`](testbench/cfs_md_sequence_simple_master.sv)
and [`cfs_md_sequence_simple_slave.sv`](testbench/cfs_md_sequence_simple_slave.sv).
The slave sequence consumes a pending monitored TX item before sending its
response, which keeps response ordering synchronized with the DUT.

## Tests

The test package is [`cfs_algn_test_pkg.sv`](testbench/cfs_algn_test_pkg.sv).
All tests extend [`cfs_algn_test_base.sv`](testbench/cfs_algn_test_base.sv),
which creates the environment.

### `cfs_algn_test_md_master_access`

This is the main data-path test. It starts a continuous randomized TX slave
response process, randomly configures the registers when the model is empty,
generates legal RX traffic, waits for processing, and reads status registers.
The default configuration sends 200 RX transfers in each of two rounds.

### `cfs_algn_illegal_rx_tr_test`

This test extends the data-path test, increases the RX transaction count to
300, and uses a factory type override to replace the legal randomized RX
virtual sequence with `cfs_algn_illegal_rx_tr_v_sequence`. It exercises RX
error responses, drop-counter saturation behavior, and `MAX_DROP` interrupt
handling.

### `cfs_algn_test_reg_access`

This test runs mapped and unmapped APB access sequences in parallel. It checks
normal register-model accesses and APB error handling for addresses outside
the register map. The default test performs 50 unmapped accesses; the mapped
access count is configurable.

## Running the Testbench

The simulation script is [`sim/run.do`](sim/run.do). It creates or refreshes
the `work` library, compiles the RTL and UVM testbench, elaborates the selected
test, and starts the simulation. Run it from ModelSim or Questa with the
project directory as the working directory.

The testbench top-level is [`testbench/testbench.sv`](testbench/testbench.sv).
Test selection and simulator-specific compile options are controlled by the
commands in `run.do` and may be changed there for a particular regression.

## Notes on Reset and Checking

The APB and MD agents, model, scoreboard, and coverage components implement
reset-aware behavior. On reset, active drivers return interface signals to
idle values, monitors stop and restart transaction collection, model state is
flushed, scoreboard queues are cleared, and register fields return to their
documented reset values. The scoreboard watchdog thresholds are configurable
through [`cfs_algn_config.sv`](testbench/cfs_algn_config.sv).
