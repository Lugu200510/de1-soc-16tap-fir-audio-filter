# Board audio codec dependencies

The original DE1-SoC course kit supplies these Intel/Altera `*.v` modules, which carry restrictive third-party notices and are **not included in the public-release ZIP**:

- `Altera_UP_Audio_Bit_Counter.v`
- `Altera_UP_Audio_In_Deserializer.v`
- `Altera_UP_Audio_Out_Serializer.v`
- `Altera_UP_Clock_Edge.v`
- `Altera_UP_I2C.v`
- `Altera_UP_I2C_AV_Auto_Initialize.v`
- `Altera_UP_I2C_DC_Auto_Initialize.v`
- `Altera_UP_I2C_LCM_Auto_Initialize.v`
- `Altera_UP_Slow_Clock_Generator.v`
- `Altera_UP_SYNC_FIFO.v`
- `audio_and_video_config.v`
- `audio_codec.v`
- `clock_generator.v`

Copy only from an authorized distribution to this folder locally. Register the `.v` files in Quartus and retain their original headers/licensing. The HDL FIR testbench requires none of these modules.
