using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage.Shared.Protocol;

namespace WindowsAzureBlobCorsTest
{
    public static class StorageWork
    {
        private static string accountName = @"radistkakat";
        private static string accountKey = @"alexUstasuSkOLKOrazGovorit/4toEtuFignyuNelzyaVIKLADIVATvOtkritiyDostup==";
        //контейнер в который будем складывать данные
        private static string containerName = @"chemodan";
        //время жизни подписи
        private static int sasTtl = 10;

        private static CloudBlobClient GetClient()
        {
            return (new CloudStorageAccount(new StorageCredentials(accountName, accountKey), true)).CreateCloudBlobClient();
        }

        /// <summary>
        /// Устанавливает нужные нам правила на сторедж
        /// </summary>
        public static void SetStorageRules()
        {
            //опишем правила для корса
            CorsRule corsRule = new CorsRule
            {

                //Список разрешенных доменов
                AllowedOrigins = new List<string>
                {
                    "*", //разрешить доступ везде
                    //"http://allowed.domain.com",
                    //"https://allowed.domain.com"
                },

                //разрешенные заголовки, спецефичные для стореджа x-ms-blob-type, x-ms-blob-content-type
                AllowedHeaders = new List<string>
                {
                    "x-ms-blob-*",
                    "content-type",
                    "accept"
                },

                //разрешить собственно запись
                AllowedMethods = CorsHttpMethods.Put,

                //Сколько кэшировать данные о корсе
                MaxAgeInSeconds=sasTtl*60
            };

            //создадим правила для стореджа

            ServiceProperties serviceProperties = new ServiceProperties
            {
                //обязательно такая (или новее, когда появится) - только у неё появился CORS
                DefaultServiceVersion = "2013-08-15",

                //вообще, следующие свойства не обязательные, но без них NullReference exception
                //установим их в дефолты
                Logging = new LoggingProperties
                {
                    Version = "1.0",
                    LoggingOperations = LoggingOperations.None
                },

                HourMetrics = new MetricsProperties
                {
                    Version = "1.0",
                    MetricsLevel = MetricsLevel.None
                },

                MinuteMetrics = new MetricsProperties
                {
                    Version = "1.0",
                    MetricsLevel = MetricsLevel.None
                }

            };
            
            //добавим правило для корса
            serviceProperties.Cors.CorsRules.Add(corsRule);

            CloudBlobClient storageClient = GetClient();

            //установим значения свойств для сервиса, достачно сделать один раз
            storageClient.SetServiceProperties(serviceProperties);

            //создадим контейнер
            CloudBlobContainer container = storageClient.GetContainerReference(containerName);
            container.CreateIfNotExists();
        }

        public static string GetStorageUrl()
        {
            return "https://" + accountName + ".blob.core.windows.net/"+containerName+"/";
        }

        public static string GetStorageSas()
        {
            return GetClient().GetContainerReference(containerName).GetSharedAccessSignature(new SharedAccessBlobPolicy
            {
                Permissions = SharedAccessBlobPermissions.Write,
                SharedAccessStartTime = DateTime.UtcNow.AddMinutes(-1),
                SharedAccessExpiryTime = DateTime.UtcNow.AddMinutes(sasTtl),
            });
        }

        /// <summary>
        /// Пример создания контейнера
        /// </summary>
        private static void CreateContainerSample()
        {
            string connectionString=@"DefaultEndpointsProtocol=https;AccountName=radistkakat;AccountKey=alexUstasuSkOLKOrazGovorit/4toEtuFignyuNelzyaVIKLADIVATvOtkritiyDostup==";
            CloudStorageAccount account = CloudStorageAccount.Parse("connectionString");
            CloudBlobClient client = account.CreateCloudBlobClient();
            CloudBlobContainer container = client.GetContainerReference("containername");
            if (container.CreateIfNotExists())
            {
                container.SetPermissions(new BlobContainerPermissions { PublicAccess = BlobContainerPublicAccessType.Blob });
            }
        }
    }
}