/**
 * @file llfloaterestim.h
 * @brief E-Stim Device Controls UI Floater header
 */

#pragma once

#include "llfloater.h"
#include "llscrolllistctrl.h"

class LLFloaterEstim : public LLFloater
{
public:
    LLFloaterEstim(const LLSD& key);
    ~LLFloaterEstim() override = default;

    bool postBuild() override;
    void draw() override;

private:
    void onPanicPressed();
    void updateCommandList();
    void drawGraph();

    LLScrollListCtrl* mCommandList{ nullptr };
    std::vector<U32> mPowerHistoryA;
    std::vector<U32> mPowerHistoryB;
};
