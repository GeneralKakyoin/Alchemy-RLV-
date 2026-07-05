/**
 * @file llfloaterestim.cpp
 * @brief E-Stim Device Controls UI Floater implementation
 */

#include "llviewerprecompiledheaders.h"
#include "llfloaterestim.h"
#include "llestimwsmgr.h"
#include "llbutton.h"
#include "lltextbox.h"
#include "llscrolllistctrl.h"
#include "llrender.h"
#include "llui.h"

LLFloaterEstim::LLFloaterEstim(const LLSD& key)
    : LLFloater(key)
{
}

bool LLFloaterEstim::postBuild()
{
    mCommandList = getChild<LLScrollListCtrl>("command_log");

    LLButton* panic_btn = getChild<LLButton>("panic_button");
    if (panic_btn)
    {
        panic_btn->setCommitCallback(boost::bind(&LLFloaterEstim::onPanicPressed, this));
    }

    return true;
}

void LLFloaterEstim::onPanicPressed()
{
    if (auto server = LLEstimWSServer::getInstance())
    {
        server->panicStop();
    }
}

void LLFloaterEstim::draw()
{
    LLFloater::draw();

    auto server = LLEstimWSServer::getInstance();
    if (!server)
    {
        return;
    }

    LLTextBox* status_txt = getChild<LLTextBox>("status_label");
    if (status_txt)
    {
        status_txt->setText(LLStringExplicit(server->isConnected() ? "Connection: Connected" : "Connection: Disconnected"));
    }

    LLTextBox* battery_txt = getChild<LLTextBox>("battery_label");
    if (battery_txt)
    {
        battery_txt->setText(LLStringExplicit("Coyote Battery: " + std::to_string((int)server->getCoyoteBattery()) + "%"));
    }

    updateCommandList();

    // Record power history for graphing
    U32 valA = server->getChannelAIntensity();
    U32 valB = server->getChannelBIntensity();
    
    mPowerHistoryA.push_back(valA);
    mPowerHistoryB.push_back(valB);
    
    // Cap history length to 300 points
    while (mPowerHistoryA.size() > 300)
    {
        mPowerHistoryA.erase(mPowerHistoryA.begin());
        mPowerHistoryB.erase(mPowerHistoryB.begin());
    }

    drawGraph();
}

void LLFloaterEstim::updateCommandList()
{
    if (!mCommandList)
    {
        return;
    }

    auto server = LLEstimWSServer::getInstance();
    if (!server)
    {
        return;
    }

    const auto& log = server->getCommandLog();
    mCommandList->clearRows();

    for (const auto& cmd : log)
    {
        LLSD element;
        element["columns"][0]["column"] = "command";
        element["columns"][0]["type"]   = "text";
        element["columns"][0]["value"]  = cmd;
        mCommandList->addElement(element);
    }

    // Auto-scroll to the bottom
    mCommandList->selectNthRow(log.empty() ? 0 : log.size() - 1);
}

void LLFloaterEstim::drawGraph()
{
    // The graph area corresponds to top=245 to 345 in a 420-height floater.
    // Local draw coordinates (y is 0 at the bottom of the floater):
    // height = 420.
    // Graph area: bottom = 420 - 345 = 75, top = 420 - 245 = 175.
    // Width: left = 10, right = 330.
    LLRect graph_rect(10, 175, 330, 75);

    // Draw background
    gGL.getTexUnit(0)->unbind(LLTexUnit::TT_TEXTURE);
    gGL.color4f(0.02f, 0.02f, 0.02f, 0.9f);
    gl_rect_2d(graph_rect, true);

    // Draw border
    gGL.color4f(0.25f, 0.25f, 0.25f, 1.0f);
    gl_rect_2d(graph_rect, false);

    // Draw grid line (horizontal 50% line)
    gGL.color4f(0.12f, 0.12f, 0.12f, 0.6f);
    gGL.begin(LLRender::LINES);
        gGL.vertex2i(graph_rect.mLeft, graph_rect.mBottom + 50);
        gGL.vertex2i(graph_rect.mRight, graph_rect.mBottom + 50);
    gGL.end();

    if (mPowerHistoryA.empty())
    {
        return;
    }

    F32 width = (F32)graph_rect.getWidth();
    F32 height = (F32)graph_rect.getHeight();
    F32 x_scale = width / 300.0f; // Max 300 history points

    // Draw Channel A (Cyan)
    gGL.color4f(0.0f, 0.85f, 0.85f, 1.0f); // Sleek cyan
    gGL.begin(LLRender::LINE_STRIP);
    for (size_t i = 0; i < mPowerHistoryA.size(); ++i)
    {
        F32 x = graph_rect.mLeft + (F32)i * x_scale;
        F32 y = graph_rect.mBottom + ((F32)mPowerHistoryA[i] / 255.0f) * height;
        gGL.vertex2f(x, y);
    }
    gGL.end();

    // Draw Channel B (Magenta)
    gGL.color4f(0.9f, 0.0f, 0.9f, 1.0f); // Sleek magenta
    gGL.begin(LLRender::LINE_STRIP);
    for (size_t i = 0; i < mPowerHistoryB.size(); ++i)
    {
        F32 x = graph_rect.mLeft + (F32)i * x_scale;
        F32 y = graph_rect.mBottom + ((F32)mPowerHistoryB[i] / 255.0f) * height;
        gGL.vertex2f(x, y);
    }
    gGL.end();
}
