FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["LewisStores.Api.csproj", "./"]
RUN dotnet restore "./LewisStores.Api.csproj"
COPY . .
RUN dotnet build "LewisStores.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "LewisStores.Api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "LewisStores.Api.dll"]
