Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Runtime.WindowsRuntime

$asTaskGeneric = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
    $_.Name -eq 'AsTask' -and 
    $_.GetParameters().Count -eq 1 -and 
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
}[0]

function AwaitOperation($asyncOp, $type) {
    $method = $asTaskGeneric.MakeGenericMethod($type)
    $task = $method.Invoke($null, @($asyncOp))
    $task.Wait()
    return $task.Result
}

$asTaskAction = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
    $_.Name -eq 'AsTask' -and 
    $_.GetParameters().Count -eq 1 -and 
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' 
}[0]

function AwaitAction($asyncAct) {
    $task = $asTaskAction.Invoke($null, @($asyncAct))
    $task.Wait()
}

[Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null

function Convert-PdfToPng($pdfPath, $pngPath) {
    $resolved = (Resolve-Path $pdfPath).Path
    $fileOp = [Windows.Storage.StorageFile]::GetFileFromPathAsync($resolved)
    $file = AwaitOperation $fileOp ([Windows.Storage.StorageFile])
    
    $pdfOp = [Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)
    $pdfDoc = AwaitOperation $pdfOp ([Windows.Data.Pdf.PdfDocument])
    
    $page = $pdfDoc.GetPage(0)
    
    $memStream = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
    $renderOptions = New-Object Windows.Data.Pdf.PdfPageRenderOptions
    $renderOptions.DestinationWidth = [uint32]1600
    
    $renderAct = $page.RenderToStreamAsync($memStream, $renderOptions)
    AwaitAction $renderAct
    
    $netStream = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($memStream)
    $img = [System.Drawing.Image]::FromStream($netStream)
    $img.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
    $netStream.Dispose()
    $memStream.Dispose()
    $page.Dispose()
    Write-Host "Successfully rendered $pdfPath to $pngPath"
}

Convert-PdfToPng "C:\Users\Priyanka\.gemini\antigravity-ide\brain\6609c9a0-1dc2-41d5-9465-9fb829bcff3d\.user_uploaded\media_1789149599198.pdf" "d:\Resume\portfolio\assets\cert-data-science.png"
Convert-PdfToPng "C:\Users\Priyanka\.gemini\antigravity-ide\brain\6609c9a0-1dc2-41d5-9465-9fb829bcff3d\.user_uploaded\media_1789149624358.pdf" "d:\Resume\portfolio\assets\cert-postgresql.png"

Copy-Item "C:\Users\Priyanka\.gemini\antigravity-ide\brain\6609c9a0-1dc2-41d5-9465-9fb829bcff3d\.user_uploaded\media_1789149599198.pdf" "d:\Resume\portfolio\assets\cert-data-science.pdf"
Copy-Item "C:\Users\Priyanka\.gemini\antigravity-ide\brain\6609c9a0-1dc2-41d5-9465-9fb829bcff3d\.user_uploaded\media_1789149624358.pdf" "d:\Resume\portfolio\assets\cert-postgresql.pdf"
