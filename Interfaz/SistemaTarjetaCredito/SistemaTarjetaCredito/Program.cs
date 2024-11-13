using Microsoft.AspNetCore.Localization;
using System.Globalization;


var builder = WebApplication.CreateBuilder(args);


// Add services to the container.
builder.Services.AddControllersWithViews();

builder.Services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();

builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(180);
});



var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
}

app.UseStaticFiles();
app.UseSession();

app.UseRouting();

app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");



var enUsCulture = new CultureInfo("en-US");
var localizationOptions = new RequestLocalizationOptions()
{
    SupportedCultures = new List<CultureInfo>()
        {
            enUsCulture
        },
    SupportedUICultures = new List<CultureInfo>()
        {
            enUsCulture
        },
    DefaultRequestCulture = new RequestCulture(enUsCulture),
    FallBackToParentCultures = false,
    FallBackToParentUICultures = false,
    RequestCultureProviders = null
};

app.UseRequestLocalization(localizationOptions);

app.Run();
