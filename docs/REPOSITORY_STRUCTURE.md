# Completed Repository Structure

```text
project-legion/
â”œâ”€â”€ .github/{ISSUE_TEMPLATE,workflows}/
â”œâ”€â”€ config/{vehicles,controllers,currents,experiments,schemas}/
â”œâ”€â”€ docs/{architecture,interfaces,safety,verification,experiments,research,thesis}/
â”œâ”€â”€ models/
â”‚   â”œâ”€â”€ matlab/{+legion,parameters,tests,examples}/
â”‚   â”œâ”€â”€ simulink/{libraries,plants,controllers,harnesses,data_dictionaries}/
â”‚   â””â”€â”€ python/{project_legion,tests,examples}/
â”œâ”€â”€ ros2_ws/src/{legion_interfaces,legion_bringup,legion_description,legion_plant_bridge,legion_serial_bridge,legion_control,legion_experiment_manager,legion_safety,legion_analysis}/
â”œâ”€â”€ firmware/stm32/{Core,Drivers,Middlewares,CubeMX,App,Tests}/
â”œâ”€â”€ rl/{environments,policies,training,evaluation,checkpoints,tests}/
â”œâ”€â”€ experiments/{manifests,seeds,results,reports}/
â”œâ”€â”€ tools/{protocol,codegen,fault_injection,latency}/
â”œâ”€â”€ scripts/{setup,build,run,analyze}/
â”œâ”€â”€ tests/{unit,integration,pil,hil,fixtures}/
â””â”€â”€ third_party/
```

Plant mathematics live under `models`; ROS 2 owns orchestration and adapters; target code lives under `firmware/stm32`; RL never owns final safety enforcement; large binary results and checkpoints belong in release or archival storage.
