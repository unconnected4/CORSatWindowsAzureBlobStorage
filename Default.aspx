<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WindowsAzureBlobCorsTest.Default" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>Windows Azure Storage Cors Test</title>
    <script type="text/javascript" src="/Scripts/jquery-1.10.2.min.js"></script>
    <script type="text/javascript">

        var maxBlockSize = 512 * 1024, //максимальный размер блока
            blockIdPrefix = "block-",
            signature = '<%=sas%>', //ключ временного доступа
            storageurl = '<%=url%>', //url стореджа вместе с контейнером
            pageLoad = (new Date()).getTime(), //просто для красоты, 
            //разнообразные переменные для работы
            files, fileIndex, 
            blockSize, numberOfBlocks, reader, streamPointer, submitUri, blockIds, bytesRemain, bytesUploaded;

        $(document).ready(function () {
            if (!(window.File || window.FileReader || window.FileList || window.Blob)){
                $('body').html('<h1>Обновите брузер. В этом ничего работать не будет</h1>');
                return;
            }
            $("#file").bind('change', processFiles);
            $('#upload').click(startUpload);
            sasActive();
        });

function processFiles(e)
{
    $('#output').children('pre').remove();
    $('#upload').hide();
    fileIndex = 0;
    files = e.target.files;
    if (!files[0].name) {
        return;
    }
    $('#upload').show();
    for (i in files) {
        if (!files[i].name) {
            return;
        }
        $fileblock = $('<pre>').css('font-family', '"Courier New", Courier, monospace');
        ($('<div>').text('Имя       : ' + files[i].name)).appendTo($fileblock);
        ($('<div>').text('Размер    : ' + files[i].size)).appendTo($fileblock);
        ($('<div>').text('Тип       : ' + files[i].type)).appendTo($fileblock);
        ($('<div>').text('Загружено : 0%')).attr('id','progress_'+i).appendTo($fileblock);
        $fileblock.insertBefore($('#upload'));
    }
}

function startUpload() {
    if (files[fileIndex] && files[fileIndex].name) {
        $('#upload').hide();
        if (files[fileIndex].size < maxBlockSize) {
            blockSize = files[fileIndex].size;
        } else {
            blockSize = maxBlockSize;
        }
        if (files[fileIndex].size % blockSize == 0) {
            numberOfBlocks = files[fileIndex].size / blockSize;
        } else {
            numberOfBlocks = parseInt(files[fileIndex].size / blockSize, 10) + 1;
        }
        blockIds = [];
        streamPointer = 0;
        submitUri = storageurl + files[fileIndex].name + signature;
        bytesRemain = files[fileIndex].size;
        bytesUploaded = 0;
        reader = new FileReader();
        reader.onloadend = uploadBlock; //отправить прочитанный кусок в сторедж
        processFile();
    }
}

function processFile() {
    if (bytesRemain > 0) {
        //сделаем название чанка
        blockIds.push(btoa(blockId()));

        //читаем кусок файла
        var fileContent = files[fileIndex].slice(streamPointer, streamPointer + blockSize);
        reader.readAsArrayBuffer(fileContent);
        streamPointer += blockSize;
        bytesRemain -= blockSize;
        if (bytesRemain < blockSize) {
            blockSize = bytesRemain;
        }
    } else {
        //все прочитали, сказать стореджу склеить блоки
        commitBlocks();
    }
}

//отправить прочитанный кусок в сторедж
function uploadBlock(e) {
    if (e.target.readyState == FileReader.DONE) { // DONE == 2
        //скажем какой кусок файла загружаем
        var uri = submitUri + '&comp=block&blockid=' + blockIds[blockIds.length - 1];
        var requestData = new Uint8Array(e.target.result);
        $.ajax({
            url: uri,
            type: "PUT",
            data: requestData,
            processData: false,
            beforeSend: function (xhr) {
                //preflight request
                xhr.setRequestHeader('x-ms-blob-type', 'BlockBlob');
                xhr.setRequestHeader('Content-Length', requestData.length);
            },
            success: function () {
                bytesUploaded += requestData.length;
                var percentage = ((parseFloat(bytesUploaded) / parseFloat(files[fileIndex].size)) * 100).toFixed(2);
                $('#progress_'+fileIndex).text('Загружено : ' + percentage + '%');
                processFile();
            },
            error: function () {
                $('#progress_' + fileIndex).text('Сбой загрузки');
            }
        });
    }
}

function commitBlocks() {
    //скажем какие блоки склевать
    var uri = submitUri + '&comp=blocklist';
    var requestBody = '<?xml version="1.0" encoding="utf-8"?><BlockList>';
    for (var i = 0; i < blockIds.length; i++) {
        requestBody += '<Latest>' + blockIds[i] + '</Latest>';
    }
    requestBody += '</BlockList>';
    $.ajax({
        url: uri,
        type: 'PUT',
        data: requestBody,
        beforeSend: function (xhr) {
            xhr.setRequestHeader('x-ms-blob-content-type', files[fileIndex].type);
            //всё тарифицируется, выставим кэш, чтобы даже самый тупой браузер закэшировал файл
            xhr.setRequestHeader('x-ms-blob-cache-control', 'max-age=31536000');
            xhr.setRequestHeader('Content-Length', requestBody.length);
        },
        success: function () {
            $('#progress_' + fileIndex).text('');
            ($('<a>').attr('href', storageurl + files[fileIndex].name).text(files[fileIndex].name)).appendTo($('#progress_' + fileIndex));
            fileIndex++;
            startUpload();
        },
        error: function () {
            $('#progress_' + fileIndex).text('Сбой загрузки');
        }
    });
}

//генератор идентификаторов блоков
function blockId() {
    var str = '' + blockIds.length;
    while (str.length < 10) {
                str = '0' + str;
    }
    return blockIdPrefix+str;
}


//проверка, что подпись не устарела
function sasActive() {
    var secElapsed=(new Date()).getTime() - pageLoad;
    if (secElapsed> 60 * 9 * 1000) {
        alert("Доступ к стореджу устарел, перегрузить страницу");
        window.location.reload();
        return;
    }
    $('#countDown').text(Math.floor(60 * 9 - secElapsed / 1000));
    setTimeout(sasActive, 1000);
};

    </script>
</head>
<body>
    <div>Действие подписи окончиться через <span id="countDown"></span> сек.</div>
    <br /><br />
    <div>Выберите файлы <input type="file" id="file" name="file" multiple="true"/></div>
    <div id="output">
        <button type="button" id="upload" style="display:none;">Загрузить</button>
    </div>
</body>
</html>
