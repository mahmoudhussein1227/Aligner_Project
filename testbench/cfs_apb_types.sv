`ifndef CFS_APB_TYPES_SV
    `define CFS_APB_TYPES_SV


    // virtual interface 
    typedef virtual cfs_apb_if cfs_apb_vif;
    
    //APB direction 
    typedef enum bit { CFS_APB_READ , CFS_APB_WRITE } cfs_apb_dir;

    //APB address
    typedef logic[`CFS_APB_MAX_ADDR_WIDTH-1:0] cfs_apb_addr;

    //APB data
    typedef logic[`CFS_APB_MAX_DATA_WIDTH-1:0] cfs_apb_data;

    // APB response
    typedef enum bit {CFS_APB_OK , CFS_APB_ERR} cfs_apb_response;
`endif