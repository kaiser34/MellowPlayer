#include <catch.hpp>
#include <MellowPlayer/Presentation/Models/StreamingServices/StreamingServicesModel.hpp>
#include <QtTest/QSignalSpy>
#include "DI.hpp"

USE_MELLOWPLAYER_NAMESPACE(UseCases)
USE_MELLOWPLAYER_NAMESPACE(Presentation)

TEST_CASE("StreamingServiceModelTests", "[UnitTest]") {
    ScopedScope scope;
    auto injector = getTestInjector(scope);
    PlayerService& playerService = injector.create<PlayerService&>();
    StreamingServicePluginService& pluginService = injector.create<StreamingServicePluginService&>();
    pluginService.load();
    QSettingsProvider settingsProvider;
    StreamingServicePlugin& plugin1 = *pluginService.getAll()[0];
    StreamingServicePlugin& plugin2 = *pluginService.getAll()[1];

    StreamingServicePluginModel model(plugin1, settingsProvider, playerService);
    StreamingServicePluginModel sameModel(plugin1, settingsProvider, playerService);
    StreamingServicePluginModel model2(plugin2, settingsProvider, playerService);

    SECTION("basic properties") {
        REQUIRE(model.getColor() == plugin1.getColor());
        REQUIRE(model.getLogo() == plugin1.getLogo());
        REQUIRE(model.getName() == plugin1.getName());
        REQUIRE(model.getPlayer() == playerService.get(plugin1.getName()).get());
        REQUIRE(model.getUrl() == plugin1.getUrl());
    }

    SECTION("equality operator") {
        REQUIRE(model != model2);
        REQUIRE(model == sameModel);
    }

    SECTION("set custom url") {
        QSignalSpy spy(&model, SIGNAL(urlChanged(const QString&)));
        model.setUrl("https://deezer.com/news");
        REQUIRE(model.getUrl() == "https://deezer.com/news");
        REQUIRE(spy.count() == 1);
    }
}