/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * See LICENSE.txt included in this distribution for the specific
 * language governing permissions and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at LICENSE.txt.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */

/*
 * Copyright (c) 2010, 2016, Oracle and/or its affiliates. All rights reserved.
 * Portions Copyright (c) 2017, Chris Fraire <cfraire@me.com>.
 */

/*
 * Cross reference a Ruby file
 */

package org.opensolaris.opengrok.analysis.ruby;

import java.io.IOException;
import java.util.Stack;
import java.util.regex.Pattern;
import org.opensolaris.opengrok.analysis.JFlexSymbolMatcher;
import org.opensolaris.opengrok.web.HtmlConsts;
%%
%public
%class RubyXref
%extends JFlexSymbolMatcher
%implements RubyLexer
%unicode
%int
%char
%init{
    h = getNewHelper();
    yyline = 1;
%init}
%include CommonLexer.lexh
%include CommonXref.lexh
%{
    protected Stack<RubyLexHelper> helpers;

    private RubyLexHelper h;

    /**
     * Resets the Ruby tracked state; {@inheritDoc}
     */
    @Override
    public void reset() {
        super.reset();
        if (helpers != null) helpers.clear();
        h.reset();
    }

    @Override
    public void offer(String value) throws IOException {
        onNonSymbolMatched(value, yychar);
    }

    @Override
    public boolean offerSymbol(String value, int captureOffset,
        boolean ignoreKwd)
            throws IOException {
        if (h.nameLength(value) <= 1) {
            onNonSymbolMatched(value, yychar);
            return false;
        } else if (ignoreKwd) {
            return onFilteredSymbolMatched(value, yychar, null);
        } else {
            return onFilteredSymbolMatched(value, yychar, Consts.kwd);
        }
    }

    @Override
    public void skipSymbol() {
        // noop
    }

    @Override
    public void offerKeyword(String value) throws IOException {
        onKeywordMatched(value, yychar);
    }

    @Override
    public void startNewLine() throws IOException {
        onEndOfLineMatched("\n", yychar);
    }

    @Override
    public void disjointSpan(String className) throws IOException {
        onDisjointSpanChanged(className, yychar);
    }

    /**
     * If the state is YYINITIAL, then transitions to INTRA; otherwise does
     * nothing, because other transitions would have saved the state.
     */
    public void maybeIntraState() {
        if (yystate() == YYINITIAL) yybegin(INTRA);
    }

    protected void pushHelper() {
        if (helpers == null) helpers = new Stack<>();
        helpers.push(h);
        h = getNewHelper();
    }

    public void popHelper() {
        h = helpers.pop();
    }

    protected RubyLexHelper getNewHelper() {
        return new RubyLexHelper(QUO, QUOxN, QUOxL, QUOxLxN, this,
            HERE, HERExN, HEREin, HEREinxN, SCOMMENT, POD);
    }

    protected boolean takeAllContent() {
        return true;
    }

    protected boolean returnOnSymbol() {
        return false;
    }

    protected void skipLink(String s, Pattern p) { /* noop */ }
%}

%include Common.lexh
%include CommonURI.lexh
%include CommonPath.lexh
%include RubyProductions.lexh
