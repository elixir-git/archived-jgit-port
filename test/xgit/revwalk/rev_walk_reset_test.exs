/*
 * Copyright (C) 2011, Garmin International
 * Copyright (C) 2011, Jesse Greenwald <jesse.greenwald@gmail.com>
 * and other copyright owners as documented in the project's IP log.
 *
 * This program and the accompanying materials are made available
 * under the terms of the Eclipse Distribution License v1.0 which
 * accompanies this distribution, is reproduced below, and is
 * available at http://www.eclipse.org/org/documents/edl-v10.php
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or
 * without modification, are permitted provided that the following
 * conditions are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above
 *   copyright notice, this list of conditions and the following
 *   disclaimer in the documentation and/or other materials provided
 *   with the distribution.
 *
 * - Neither the name of the Eclipse Foundation, Inc. nor the
 *   names of its contributors may be used to endorse or promote
 *   products derived from this software without specific prior
 *   written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package org.eclipse.jgit.revwalk;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicBoolean;

import org.eclipse.jgit.errors.IncorrectObjectTypeException;
import org.eclipse.jgit.errors.MissingObjectException;
import org.eclipse.jgit.errors.StopWalkException;
import org.eclipse.jgit.revwalk.filter.RevFilter;
import org.junit.Test;

public class RevWalkResetTest extends RevWalkTestCase {

  @Test
  public void testRevFilterReceivesParsedCommits() throws Exception {
    final RevCommit a = commit();
    final RevCommit b = commit(a);
    final RevCommit c = commit(b);

    final AtomicBoolean filterRan = new AtomicBoolean();
    RevFilter testFilter = new RevFilter() {

      @Override
      public boolean include(RevWalk walker, RevCommit cmit)
          throws StopWalkException, MissingObjectException,
          IncorrectObjectTypeException, IOException {
        assertNotNull("commit is parsed", cmit.getRawBuffer());
        filterRan.set(true);
        return true;
      }

      @Override
      public RevFilter clone() {
        return this;
      }

      @Override
      public boolean requiresCommitBody() {
        return true;
      }
    };

    // Do an initial run through the walk
    filterRan.set(false);
    rw.setRevFilter(testFilter);
    markStart(c);
    rw.markUninteresting(b);
    for (RevCommit cmit = rw.next(); cmit != null; cmit = rw.next()) {
      // Don't dispose the body here, because we want to test the effect
      // of marking 'b' as uninteresting.
    }
    assertTrue("filter ran", filterRan.get());

    // Run through the walk again, this time disposing of all commits.
    filterRan.set(false);
    rw.reset();
    markStart(c);
    for (RevCommit cmit = rw.next(); cmit != null; cmit = rw.next()) {
      cmit.disposeBody();
    }
    assertTrue("filter ran", filterRan.get());

    // Do the third run through the reused walk. Test that the explicitly
    // disposed commits are parsed on this walk.
    filterRan.set(false);
    rw.reset();
    markStart(c);
    for (RevCommit cmit = rw.next(); cmit != null; cmit = rw.next()) {
      // spin through the walk.
    }
    assertTrue("filter ran", filterRan.get());

  }
}
