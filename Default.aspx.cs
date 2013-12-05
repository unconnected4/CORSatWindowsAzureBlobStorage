using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WindowsAzureBlobCorsTest
{
    public partial class Default : System.Web.UI.Page
    {
        public string url;
        public string sas;

        protected void Page_Load(object sender, EventArgs e)
        {
            url = StorageWork.GetStorageUrl();
            sas = StorageWork.GetStorageSas();
        }
    }
}